"""Multi-stop trip preparation, reverse loading order and shipment closure."""
from datetime import date
from uuid import uuid4
import hashlib
from backend.app.repositories.demo import BusinessError, dump, now
from backend.app.repositories.demo_queries import HU_SQL, LINE_SQL
from backend.app.services.demo_warehouse import required
from backend.app.services.demo_catalog import route_for_units

def create_trip(db,ctx,payload,operation):
    if db.one("SELECT Id FROM shipping.Shipment WHERE TrailerId=? AND ClosedAtUtc IS NULL AND CancelledAtUtc IS NULL",ctx["trailer"]):
        raise BusinessError("Cierra el viaje abierto antes de asignar de nuevo el tráiler DEMO.")
    requested=payload.get("unit_ids")
    available=[r for r in db.rows(HU_SQL) if r["estado"]=="STAGED" and r["shipment_id"] is None]
    if requested is not None and (not isinstance(requested,list) or any(type(i) is not int for i in requested)
                                  or len(set(requested))!=len(requested)
                                  or not set(requested).issubset({r["id"] for r in available})):
        raise BusinessError("Las tarimas disponibles cambiaron. Actualiza y revisa el viaje.")
    units=[r for r in available if requested is None or r["id"] in requested]
    if not units: raise BusinessError("No hay tarimas disponibles en preembarque.")
    from backend.app.services.demo_familiar import warehouse_context
    ctx=warehouse_context(db,ctx,units[0]["WarehouseId"])
    route=route_for_units(db,units)
    destinations=[r["id"] for r in route]
    # Reject a stale preview: changing a distance requires reviewing the proposal again.
    if "distance_ids" in payload and payload["distance_ids"]!=[r["distance_id"] for r in route]:
        raise BusinessError("Los destinos cambiaron. Actualiza y revisa de nuevo la propuesta.")
    code="DEMO-VIA-"+uuid4().hex[:8].upper()
    trip=db.insert("planning.Trip",Code=code,OriginWarehouseId=ctx["warehouse"],Status="RELEASED")
    origin=db.scalar("SELECT pa.Id FROM catalog.PointAddress pa JOIN catalog.Warehouse w ON w.PointId=pa.PointId WHERE w.Id=? AND pa.VersionNumber=1",ctx["warehouse"])
    revision=db.insert("planning.TripRevision",TripId=trip,RevisionNumber=1,OriginAddressId=origin,
                       PlannedDepartureUtc=now(),PlannedTrailerId=ctx["trailer"],PlannedDriverId=ctx["driver"],
                       Status="APPROVED",ApprovedBy=ctx["actor"],ApprovedAtUtc=now(),ChangeReason="Propuesta por kilómetros desde almacén, de menor a mayor; no optimización vial")
    db.execute("UPDATE planning.Trip SET CurrentRevisionId=? WHERE Id=?",revision,trip)
    shipment=db.insert("shipping.Shipment",TripId=trip,TripRevisionId=revision,TrailerId=ctx["trailer"],
                       DriverId=ctx["driver"],DockLocationId=ctx["locations"]["DOCK"],Status="OPEN",OpenedAtUtc=now())
    stops={}
    for seq,row in enumerate(route,1):
        # Instructions holds an immutable demo route snapshot. A warehouse distance is
        # deliberately NOT written to DistanceFromPreviousId (that FK denotes a leg).
        instructions=dump(dict(basis="warehouse",km=row["km"],destination=row["nombre"],
                               distance_id=row["distance_id"]))
        stops[row["id"]]=db.insert("planning.TripStop",TripRevisionId=revision,SequenceNumber=seq,
            DeliverySiteId=row["id"],AddressVersionId=row["address_id"],Instructions=instructions)
    for hu in units:
        stop=stops[hu["DeliverySiteId"]]
        existing=db.one("SELECT Id FROM planning.TripAllocation WHERE StopId=? AND AllocationId=?",stop,hu["AllocationId"])
        if existing:
            db.execute("UPDATE planning.TripAllocation SET PlannedBaseQuantity=PlannedBaseQuantity+?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",hu["cantidad"],existing["Id"])
        else:
            db.insert("planning.TripAllocation",StopId=stop,AllocationId=hu["AllocationId"],PlannedBaseQuantity=hu["cantidad"],
                      CancelledBaseQuantity=0,Status="RELEASED")
        db.insert("shipping.ShipmentUnit",ShipmentId=shipment,TripRevisionId=revision,StopId=stop,HandlingUnitId=hu["id"],
                  Status="ASSIGNED",AssignedBy=ctx["actor"],AssignedAtUtc=now())
    return dict(message=f"{code}: {len(units)} tarimas y {len(stops)} destinos. Carga primero la última parada.",shipment_id=shipment)

def load(db,ctx,payload,operation):
    hu=next((r for r in db.rows(HU_SQL) if r["id"]==payload["id"]),None)
    if not hu or not hu["shipment_id"] or hu["estado"]!="STAGED":
        raise BusinessError("La tarima debe estar en preembarque y asignada a un viaje abierto.")
    shipment=required(db,"SELECT Id,Status,DockLocationId FROM shipping.Shipment WHERE Id=?",hu["shipment_id"])
    if shipment["Status"] not in ("OPEN","LOADING"): raise BusinessError("El viaje ya está cerrado.")
    next_stop=db.scalar("""SELECT MAX(st.SequenceNumber) FROM shipping.ShipmentUnit su JOIN planning.TripStop st ON st.Id=su.StopId
WHERE su.ShipmentId=? AND su.Status='ASSIGNED'""",shipment["Id"])
    if hu["parada"]!=next_stop: raise BusinessError(f"Carga primero las tarimas de la parada {next_stop}; se descargará al final.")
    if payload.get("code")!=hu["codigo"]: raise BusinessError("El código de tarima no coincide.")
    db.insert("shipping.LoadEvent",ShipmentUnitId=hu["shipment_unit_id"],EventType="LOAD",WarehouseLocationId=shipment["DockLocationId"],
              ActorUserId=ctx["actor"],OperationId=operation,OccurredAtUtc=now(),Reason="Carga simulada")
    db.execute("UPDATE shipping.ShipmentUnit SET Status='LOADED',UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",hu["shipment_unit_id"])
    db.execute("UPDATE warehouse.HandlingUnit SET Status='LOADED',CurrentLocationId=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",shipment["DockLocationId"],hu["id"])
    db.execute("UPDATE shipping.Shipment SET Status='LOADING',UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",shipment["Id"])
    return dict(message="Carga confirmada: "+hu["codigo"])

def close(db,ctx,payload,operation):
    shipment=required(db,"SELECT s.Id,s.TripId,s.Status FROM shipping.Shipment s JOIN planning.Trip t ON t.Id=s.TripId WHERE s.Id=? AND t.Code LIKE 'DEMO-VIA-%'",payload["id"])
    if shipment["Status"]!="LOADING": raise BusinessError("El viaje no está en carga.")
    units=[r for r in db.rows(HU_SQL) if r["shipment_id"]==shipment["Id"]]
    if not units or any(r["estado"]!="LOADED" for r in units):
        raise BusinessError("Faltan tarimas por cargar. No se puede cerrar el viaje.")
    seal=str(payload.get("seal","")).strip()
    if not 1<=len(seal)<=50: raise BusinessError("Captura un sello de entre 1 y 50 caracteres.")
    manifest=dump(dict(simulated=True,shipment=shipment["Id"],seal=seal,units=units))
    db.insert("shipping.ShipmentClosure",ShipmentId=shipment["Id"],ClosedBy=ctx["actor"],OperationId=operation,
              ClosedAtUtc=now(),ManifestJson=manifest,ManifestHash=hashlib.sha256(manifest.encode()).digest(),IsPartial=False)
    db.execute("UPDATE shipping.Shipment SET Status='CLOSED',SealNumber=?,ClosedAtUtc=SYSUTCDATETIME(),UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",seal,shipment["Id"])
    db.execute("UPDATE shipping.ShipmentUnit SET Status='DISPATCHED',UpdatedAtUtc=SYSUTCDATETIME() WHERE ShipmentId=?",shipment["Id"])
    db.execute("UPDATE warehouse.HandlingUnit SET Status='SHIPPED',UpdatedAtUtc=SYSUTCDATETIME() WHERE Id IN (SELECT HandlingUnitId FROM shipping.ShipmentUnit WHERE ShipmentId=?)",shipment["Id"])
    db.execute("UPDATE planning.Trip SET Status='CLOSED',UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",shipment["TripId"])
    db.execute("UPDATE planning.TripAllocation SET Status='COMPLETED',UpdatedAtUtc=SYSUTCDATETIME() WHERE StopId IN (SELECT StopId FROM shipping.ShipmentUnit WHERE ShipmentId=?)",shipment["Id"])

    lines=db.rows(LINE_SQL)
    orders={}
    for line in lines:
        if line["embarcado"]==line["cantidad"]:
            db.execute("UPDATE operations.OrderLine SET IsClosed=1,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",line["id"])
        orders.setdefault(line["pedido"],[]).append(line)
    for order,items in orders.items():
        state="COMPLETED" if all(r["embarcado"]==r["cantidad"] for r in items) else "IN_PROGRESS" if any(r["recogido"]>0 for r in items) else "RELEASED" if any(r["planeado"]>0 for r in items) else "CREATED"
        db.execute("UPDATE operations.SalesOrder SET Status=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE SourceSystemId=? AND ExternalOrderNumber=?",state,ctx["source"],order)
    for alloc in {hu["AllocationId"] for hu in units}:
        shipped=db.scalar("""SELECT COALESCE(SUM(i.BaseQuantity),0) FROM warehouse.PickingTaskLine tl
JOIN warehouse.PickConfirmation pc ON pc.TaskLineId=tl.Id
JOIN warehouse.PackingReceipt pr ON pr.PickConfirmationId=pc.Id
JOIN warehouse.HandlingUnitItem i ON i.ReceiptId=pr.Id
JOIN warehouse.HandlingUnit hu ON hu.Id=i.HandlingUnitId AND hu.Status='SHIPPED' WHERE tl.AllocationId=?""",alloc)
        db.execute("UPDATE operations.FulfillmentAllocation SET Status=CASE WHEN AllocatedBaseQuantity=? THEN 'COMPLETED' ELSE 'IN_PROGRESS' END,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",shipped,alloc)
    return dict(message="Embarque cerrado. El manifiesto y la trazabilidad quedaron guardados.",shipment_id=shipment["Id"])
