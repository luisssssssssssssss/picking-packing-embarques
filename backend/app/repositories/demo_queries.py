"""Read models for the desktop dashboard, derived from durable operational events."""
import json
from backend.app.repositories.demo import transaction
from backend.app.services.demo_catalog import destinations
from backend.app.services.demo_seed import SOURCE

LINE_SQL = """
SELECT l.Id AS id, so.ExternalOrderNumber AS pedido, l.ExternalLineKey AS linea,
 r.Id AS revision_id,r.MaterialId,r.DeliverySiteId,r.RequestedDate AS fecha,
 r.RequiredBaseQuantity AS cantidad,r.MaterialCodeSnapshot AS material,
 m.Description AS descripcion,c.Name AS cliente,ds.Name AS destino,
 COALESCE(a.qty,0) AS planeado,COALESCE(p.qty,0) AS recogido,
 COALESCE(k.qty,0) AS empacado,COALESCE(sh.qty,0) AS embarcado
FROM operations.OrderLine l
JOIN operations.SalesOrder so ON so.Id=l.OrderId
JOIN integration.SourceSystem src ON src.Id=so.SourceSystemId AND src.Code='DEMO_DESKTOP'
JOIN operations.OrderLineRevision r ON r.OrderLineId=l.Id AND r.OrderRevisionId=so.CurrentRevisionId
JOIN catalog.Customer c ON c.Id=so.CustomerId
JOIN catalog.Material m ON m.Id=r.MaterialId
JOIN catalog.DeliverySite ds ON ds.Id=r.DeliverySiteId
OUTER APPLY (SELECT SUM(AllocatedBaseQuantity) qty FROM operations.FulfillmentAllocation WHERE OrderLineId=l.Id AND Status<>'CANCELLED') a
OUTER APPLY (SELECT SUM(pc.BaseQuantity) qty FROM operations.FulfillmentAllocation fa JOIN warehouse.PickingTaskLine tl ON tl.AllocationId=fa.Id JOIN warehouse.PickConfirmation pc ON pc.TaskLineId=tl.Id WHERE fa.OrderLineId=l.Id) p
OUTER APPLY (SELECT SUM(i.BaseQuantity) qty FROM operations.FulfillmentAllocation fa JOIN warehouse.PickingTaskLine tl ON tl.AllocationId=fa.Id JOIN warehouse.PickConfirmation pc ON pc.TaskLineId=tl.Id JOIN warehouse.PackingReceipt pr ON pr.PickConfirmationId=pc.Id JOIN warehouse.HandlingUnitItem i ON i.ReceiptId=pr.Id WHERE fa.OrderLineId=l.Id) k
OUTER APPLY (SELECT SUM(i.BaseQuantity) qty FROM operations.FulfillmentAllocation fa JOIN warehouse.PickingTaskLine tl ON tl.AllocationId=fa.Id JOIN warehouse.PickConfirmation pc ON pc.TaskLineId=tl.Id JOIN warehouse.PackingReceipt pr ON pr.PickConfirmationId=pc.Id JOIN warehouse.HandlingUnitItem i ON i.ReceiptId=pr.Id JOIN warehouse.HandlingUnit hu ON hu.Id=i.HandlingUnitId AND hu.Status='SHIPPED' WHERE fa.OrderLineId=l.Id) sh
"""
TASK_SQL = """
SELECT au.DisplayName AS responsable,tl.Id AS id,tl.TaskId,tl.AllocationId,l.Id AS line_id,tl.PlannedBaseQuantity AS cantidad,
 so.ExternalOrderNumber AS pedido,r.MaterialCodeSnapshot AS material,m.Description AS descripcion,
 ds.Name AS destino,loc.Code AS ubicacion,loc.Name AS ubicacion_nombre,w.Id AS WarehouseId,w.Name AS almacen,tl.Status AS estado,
 cb.Id AS booking_id,cd.WorkDate AS fecha,cb.PoolId,
 COALESCE(p.qty,0) AS recogido,COALESCE(k.qty,0) AS empacado
FROM warehouse.PickingTaskLine tl
JOIN warehouse.PickingTask pt ON pt.Id=tl.TaskId
LEFT JOIN security.AppUser au ON au.Id=pt.AssignedUserId
JOIN operations.FulfillmentAllocation fa ON fa.Id=tl.AllocationId
JOIN operations.OrderLine l ON l.Id=fa.OrderLineId
JOIN operations.SalesOrder so ON so.Id=l.OrderId
JOIN integration.SourceSystem src ON src.Id=so.SourceSystemId AND src.Code='DEMO_DESKTOP'
JOIN operations.OrderLineRevision r ON r.Id=fa.OrderLineRevisionId
JOIN catalog.Material m ON m.Id=r.MaterialId
JOIN catalog.DeliverySite ds ON ds.Id=r.DeliverySiteId
JOIN catalog.Location loc ON loc.Id=tl.SourceLocationId
JOIN catalog.Warehouse w ON w.Id=loc.WarehouseId
JOIN planning.CapacityBooking cb ON cb.AllocationId=fa.Id
JOIN planning.CapacityDay cd ON cd.Id=cb.CapacityDayId
OUTER APPLY (SELECT SUM(BaseQuantity) qty FROM warehouse.PickConfirmation WHERE TaskLineId=tl.Id) p
OUTER APPLY (SELECT SUM(i.BaseQuantity) qty FROM warehouse.PickConfirmation pc JOIN warehouse.PackingReceipt pr ON pr.PickConfirmationId=pc.Id JOIN warehouse.HandlingUnitItem i ON i.ReceiptId=pr.Id WHERE pc.TaskLineId=tl.Id) k
"""
HU_SQL = """
SELECT hu.CreatedAtUtc AS fecha_empaque,hu.Id AS id,hu.Code AS codigo,hu.Status AS estado,ds.Name AS destino,
 hu.DeliverySiteId,MIN(fa.Id) AS AllocationId,MIN(r.OrderLineId) AS line_id,
 w.Id AS WarehouseId,w.Name AS almacen,loc.Name AS ubicacion_nombre,loc.Code AS ubicacion,
 MIN(so.ExternalOrderNumber) AS pedido,MIN(r.MaterialCodeSnapshot) AS material,MIN(m.Description) AS descripcion,
 SUM(i.BaseQuantity) AS cantidad,
 su.Id AS shipment_unit_id,su.ShipmentId AS shipment_id,ts.SequenceNumber AS parada
FROM warehouse.HandlingUnit hu
JOIN catalog.Warehouse w ON w.Id=hu.WarehouseId
LEFT JOIN catalog.Location loc ON loc.Id=hu.CurrentLocationId
JOIN catalog.DeliverySite ds ON ds.Id=hu.DeliverySiteId
JOIN warehouse.HandlingUnitItem i ON i.HandlingUnitId=hu.Id
JOIN warehouse.PackingReceipt pr ON pr.Id=i.ReceiptId
JOIN warehouse.PickConfirmation pc ON pc.Id=pr.PickConfirmationId
JOIN warehouse.PickingTaskLine tl ON tl.Id=pc.TaskLineId
JOIN operations.FulfillmentAllocation fa ON fa.Id=tl.AllocationId
JOIN operations.OrderLineRevision r ON r.Id=fa.OrderLineRevisionId
JOIN catalog.Material m ON m.Id=r.MaterialId
JOIN operations.SalesOrder so ON so.Id=r.OrderId
JOIN integration.SourceSystem src ON src.Id=so.SourceSystemId AND src.Code='DEMO_DESKTOP'
LEFT JOIN shipping.ShipmentUnit su ON su.HandlingUnitId=hu.Id AND su.ReleasedAtUtc IS NULL
LEFT JOIN planning.TripStop ts ON ts.Id=su.StopId
GROUP BY hu.CreatedAtUtc,hu.Id,hu.Code,hu.Status,ds.Name,hu.DeliverySiteId,su.Id,su.ShipmentId,ts.SequenceNumber,w.Id,w.Name,loc.Name,loc.Code
"""

def snapshot():
    with transaction(False) as db:
        lines=db.rows(LINE_SQL+" ORDER BY r.RequestedDate,so.ExternalOrderNumber,l.ExternalLineKey")
        tasks=db.rows(TASK_SQL+" ORDER BY cd.WorkDate,tl.Id")
        units=db.rows(HU_SQL+" ORDER BY hu.Id DESC")
        days=db.rows("""
SELECT w.Name AS almacen,cd.Id AS id,cd.WorkDate AS fecha,cd.BaseCapacity+cd.ExtraCapacity-cd.UnavailableCapacity AS capacidad,
 COALESCE(SUM(cb.PlannedBaseQuantity-cb.ReleasedBaseQuantity),0) AS reservado
FROM planning.CapacityDay cd JOIN planning.CapacityPool p ON p.Id=cd.PoolId AND p.Code LIKE 'DEMO-PICK%'
JOIN catalog.Warehouse w ON w.Id=p.WarehouseId
LEFT JOIN planning.CapacityBooking cb ON cb.CapacityDayId=cd.Id AND cb.Status IN ('COMMITTED','COMPLETED')
GROUP BY w.Name,cd.Id,cd.WorkDate,cd.BaseCapacity,cd.ExtraCapacity,cd.UnavailableCapacity ORDER BY cd.WorkDate""")
        shipments=db.rows("""
SELECT s.Id AS id,t.Code AS viaje,s.Status AS estado,s.SealNumber AS sello,s.OpenedAtUtc AS apertura,tr.Code AS trailer,loc.Name AS anden,
 (SELECT COUNT(*) FROM shipping.ShipmentUnit WHERE ShipmentId=s.Id) AS unidades,
 (SELECT COUNT(*) FROM shipping.ShipmentUnit WHERE ShipmentId=s.Id AND Status IN ('LOADED','DISPATCHED')) AS cargadas
FROM shipping.Shipment s JOIN planning.Trip t ON t.Id=s.TripId
JOIN planning.Trailer tr ON tr.Id=s.TrailerId
LEFT JOIN catalog.Location loc ON loc.Id=s.DockLocationId
WHERE t.Code LIKE 'DEMO-VIA-%' ORDER BY s.Id DESC""")
        stops=db.rows("""
SELECT s.Id AS shipment_id,st.SequenceNumber AS secuencia,ds.Name AS destino,dr.RoadDistanceKm AS km,st.Instructions AS instructions
FROM shipping.Shipment s JOIN planning.Trip t ON t.Id=s.TripId AND t.Code LIKE 'DEMO-VIA-%'
JOIN planning.TripStop st ON st.TripRevisionId=s.TripRevisionId
JOIN catalog.DeliverySite ds ON ds.Id=st.DeliverySiteId
LEFT JOIN planning.DistanceReference dr ON dr.Id=st.DistanceFromPreviousId ORDER BY s.Id,st.SequenceNumber""")
        for stop in stops:
            # Older trips stored leg distances; newer guided trips snapshot warehouse distance.
            stop["km_basis"]="previous_stop"
            try:
                info=json.loads(stop.pop("instructions") or "")
            except (ValueError,TypeError):
                continue
            if isinstance(info,dict) and info.get("basis")=="warehouse":
                stop.update(km=info["km"],destino=info["destination"],km_basis="warehouse")
        products=db.rows("SELECT Id AS id,Code AS codigo,Description AS nombre FROM catalog.Material WHERE Code LIKE 'DEMO-%' AND IsActive=1 ORDER BY Code")
        sites=destinations(db)
        sites_by_warehouse={str(w["Id"]):destinations(db,w["Id"]) for w in db.rows("SELECT Id FROM catalog.Warehouse WHERE Code IN ('DEMO-ALM','DEMO-HUICHO')")}
        imports=db.rows("""
SELECT TOP(20) r.Id AS id,f.OriginalFileName AS archivo,r.Status AS estado,r.CreatedAtUtc AS fecha,
 (SELECT COUNT(*) FROM integration.ImportError e WHERE e.RunId=r.Id) AS errores
FROM integration.ImportRun r JOIN integration.ImportedFile f ON f.Id=r.FileId
JOIN integration.SourceSystem src ON src.Id=f.SourceSystemId AND src.Code='DEMO_DESKTOP' ORDER BY r.Id DESC""")
        errors=db.rows("""
SELECT TOP(50) e.RunId AS importacion,e.Message AS mensaje FROM integration.ImportError e
JOIN integration.ImportRun r ON r.Id=e.RunId JOIN integration.ImportedFile f ON f.Id=r.FileId
JOIN integration.SourceSystem src ON src.Id=f.SourceSystemId AND src.Code='DEMO_DESKTOP' ORDER BY e.Id DESC""")
        audit=db.rows("SELECT e.ActionCode AS accion,e.EntityKey AS referencia,e.AfterJson AS detalle,e.OccurredAtUtc AS fecha,u.DisplayName AS responsable FROM audit.AuditEvent e LEFT JOIN security.AppUser u ON u.Id=e.ActorUserId WHERE e.EntityType='DESKTOP_DEMO' ORDER BY e.Id DESC")
        operational_audit=db.rows("""SELECT TOP(8) e.ActionCode AS accion,e.AfterJson AS detalle,
e.OccurredAtUtc AS fecha,u.DisplayName AS responsable
FROM audit.AuditEvent e LEFT JOIN security.AppUser u ON u.Id=e.ActorUserId
WHERE e.EntityType='DESKTOP_DEMO' AND e.ActionCode IN ('PICK','PACK','STAGE','LOAD','CLOSE','INCIDENT')
ORDER BY e.Id DESC""")
        incidents=db.rows("""
SELECT TOP(40) i.Id AS id,i.Description AS descripcion,i.Status AS estado,i.CreatedAtUtc AS fecha
FROM quality.Incident i JOIN quality.IncidentType t ON t.Id=i.TypeId AND t.Code='DEMO-INC' ORDER BY i.Id DESC""")
        locations=db.rows("""SELECT loc.LocationType AS kind,loc.Name AS nombre,loc.Code AS codigo,w.Id AS WarehouseId,w.Name AS almacen
FROM catalog.Location loc JOIN catalog.Warehouse w ON w.Id=loc.WarehouseId
WHERE w.Code IN ('DEMO-ALM','DEMO-HUICHO') AND loc.LocationType IN ('PACKING','STAGING','DOCK') AND loc.IsActive=1""")
        state = dict(destinations_by_warehouse=sites_by_warehouse,locations=locations,products=products,destinations=sites,lines=lines,tasks=tasks,units=units,days=days,shipments=shipments,stops=stops,
                    imports=imports,errors=errors,audit=audit,operational_audit=operational_audit,incidents=incidents,
                    totals={key:sum(row[key] for row in lines) for key in ("cantidad","planeado","recogido","empacado","embarcado")})

        from backend.app.services.demo_supervisor import supervisor_view
        state["supervisor"]=supervisor_view(state)
        return state
