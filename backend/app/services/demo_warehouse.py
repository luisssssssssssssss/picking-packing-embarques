"""Daily planning and warehouse execution for a controlled simulated workflow."""
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from uuid import uuid4
from backend.app.repositories.demo import BusinessError, now
from backend.app.repositories.demo_queries import LINE_SQL, TASK_SQL, HU_SQL

def required(db,sql,*args):
    row=db.one(sql,*args)
    if not row: raise BusinessError("El registro no existe en esta demostración.")
    return row

def quantity(payload):
    try: qty=Decimal(str(payload["quantity"]))
    except Exception: raise BusinessError("Cantidad inválida.") from None
    if not qty.is_finite() or qty<=0 or qty!=qty.to_integral_value():
        raise BusinessError("La cantidad debe ser un entero positivo.")
    return qty

def day(db,ctx,value,capacity):
    row=db.one("SELECT Id,BaseCapacity,ExtraCapacity,UnavailableCapacity FROM planning.CapacityDay WHERE PoolId=? AND WorkDate=?",ctx["pool"],value)
    if row: return row["Id"]
    return db.insert("planning.CapacityDay",PoolId=ctx["pool"],WorkDate=value,
        WindowStartUtc=datetime.combine(value,time(14)),WindowEndUtc=datetime.combine(value,time(23)),
        BaseCapacity=capacity,ExtraCapacity=0,UnavailableCapacity=0,Status="OPEN",
        ChangeReason="Calendario simulado de la demo",ChangedBy=ctx["actor"])

def plan(db,ctx,payload,operation):
    try:
        start=date.fromisoformat(payload["start_date"]); capacity=int(payload["capacity"])
    except (KeyError,ValueError): raise BusinessError("Indica fecha y capacidad válidas.") from None
    if not 1<=capacity<=100000: raise BusinessError("Capacidad entre 1 y 100000 piezas.")
    lines=db.rows(LINE_SQL+" ORDER BY r.RequestedDate,so.ExternalOrderNumber,l.ExternalLineKey")
    bookings=0
    for line in lines:
        remaining=line["cantidad"]-line["planeado"]
        work=start
        while remaining>0:
            if (work-start).days>365:
                raise BusinessError("El plan excede un año; aumenta capacidad o reduce pedidos.")
            if work.weekday()>=5:
                work+=timedelta(days=1); continue
            did=day(db,ctx,work,capacity)
            free=db.scalar("""SELECT cd.BaseCapacity+cd.ExtraCapacity-cd.UnavailableCapacity-
COALESCE((SELECT SUM(b.PlannedBaseQuantity-b.ReleasedBaseQuantity) FROM planning.CapacityBooking b
WHERE b.CapacityDayId=cd.Id AND b.Status IN ('COMMITTED','COMPLETED')),0)
FROM planning.CapacityDay cd WHERE cd.Id=?""",did)
            if free<=0:
                work+=timedelta(days=1); continue
            take=min(remaining,free)
            alloc=db.insert("operations.FulfillmentAllocation",OrderLineId=line["id"],OrderLineRevisionId=line["revision_id"],
                            WarehouseId=ctx["warehouse"],AllocatedBaseQuantity=take,Status="RELEASED",ReleasedAtUtc=now(),ReleasedBy=ctx["actor"])
            standard=db.scalar("SELECT Id FROM planning.WorkStandardVersion WHERE PoolId=? AND MaterialId=? AND VersionNumber=1",ctx["pool"],line["MaterialId"])
            booking=db.insert("planning.CapacityBooking",AllocationId=alloc,PoolId=ctx["pool"],CapacityDayId=did,
                              WorkStandardVersionId=standard,PlannedBaseQuantity=take,ReleasedBaseQuantity=0,
                              Status="COMMITTED",ApprovedBy=ctx["actor"],ApprovedAtUtc=now(),LastOperationId=operation)
            task=db.insert("warehouse.PickingTask",WarehouseId=ctx["warehouse"],Code="DEMO-P-"+str(booking),AssignedUserId=ctx["actor"],Status="ASSIGNED")
            db.insert("warehouse.PickingTaskLine",TaskId=task,AllocationId=alloc,SourceLocationId=ctx["locations"]["BIN"],
                      PlannedBaseQuantity=take,Status="OPEN")
            db.execute("UPDATE operations.SalesOrder SET Status='RELEASED',UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=(SELECT OrderId FROM operations.OrderLine WHERE Id=?)",line["id"])
            remaining-=take; bookings+=1
    return dict(message=f"{bookings} tareas programadas. Se respetaron reservas existentes y fines de semana.")

def pick(db,ctx,payload,operation):
    task=required(db,TASK_SQL+" WHERE tl.Id=?",payload["id"])
    qty=quantity(payload)
    if task["estado"]=="CANCELLED" or qty>task["cantidad"]-task["recogido"]:
        raise BusinessError("No puedes recoger más de lo pendiente.")
    if payload.get("location")!=task["ubicacion"] or payload.get("material")!=task["material"]:
        raise BusinessError("El código de ubicación o material no coincide con la tarea.")
    # Demo clock: all evidence explicitly belongs to the planned simulated workday.
    occurred=datetime.combine(task["fecha"],time(16))
    confirmation=db.insert("warehouse.PickConfirmation",TaskLineId=task["id"],BaseQuantity=qty,ActorUserId=ctx["actor"],
        OperationId=operation,CaptureMethod="MANUAL",ObservedLocationCode=payload["location"],ObservedMaterialCode=payload["material"],OccurredAtUtc=occurred)
    complete=task["recogido"]+qty==task["cantidad"]
    db.execute("UPDATE operations.FulfillmentAllocation SET Status='IN_PROGRESS',UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",task["AllocationId"])
    db.execute("UPDATE warehouse.PickingTaskLine SET Status=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?","COMPLETED" if complete else "IN_PROGRESS",task["id"])
    db.execute("UPDATE warehouse.PickingTask SET Status=?,StartedAtUtc=COALESCE(StartedAtUtc,?),CompletedAtUtc=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",
               "COMPLETED" if complete else "IN_PROGRESS",occurred,occurred if complete else None,task["TaskId"])
    did=db.scalar("SELECT CapacityDayId FROM planning.CapacityBooking WHERE Id=?",task["booking_id"])
    db.insert("planning.CapacityExecution",BookingId=task["booking_id"],PoolId=task["PoolId"],ActualCapacityDayId=did,
              PickConfirmationId=confirmation,BaseQuantity=qty,UsedStandardCapacity=qty,OperationId=operation)
    if complete:
        db.execute("UPDATE planning.CapacityBooking SET Status='COMPLETED',UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",task["booking_id"])
    return dict(message=f"Picking confirmado: {qty} piezas.",simulated_date=task["fecha"])

def pack(db,ctx,payload,operation):
    task=required(db,TASK_SQL+" WHERE tl.Id=?",payload["id"])
    qty=quantity(payload)
    if qty>task["recogido"]-task["empacado"]: raise BusinessError("Solo puedes empacar material recogido y pendiente.")
    destination=db.scalar("SELECT r.DeliverySiteId FROM operations.FulfillmentAllocation a JOIN operations.OrderLineRevision r ON r.Id=a.OrderLineRevisionId WHERE a.Id=?",task["AllocationId"])
    code="DEMO-HU-"+uuid4().hex[:10].upper()
    hu=db.insert("warehouse.HandlingUnit",Code=code,TypeId=db.scalar("SELECT Id FROM catalog.HandlingUnitType WHERE Code='PALLET'"),
                 WarehouseId=ctx["warehouse"],DeliverySiteId=destination,CurrentLocationId=ctx["locations"]["PACKING"],
                 Status="PACKED",PackedAtUtc=now(),PackedBy=ctx["actor"])
    remaining=qty
    confirmations=db.rows("""SELECT pc.Id,pc.BaseQuantity-COALESCE((SELECT SUM(BaseQuantity) FROM warehouse.PackingReceipt WHERE PickConfirmationId=pc.Id),0) AS available
FROM warehouse.PickConfirmation pc WHERE pc.TaskLineId=? ORDER BY pc.Id""",task["id"])
    for pc in confirmations:
        take=min(remaining,pc["available"])
        if take<=0: continue
        receipt=db.insert("warehouse.PackingReceipt",PickConfirmationId=pc["Id"],PackingLocationId=ctx["locations"]["PACKING"],
                          BaseQuantity=take,ReceivedBy=ctx["actor"],OperationId=operation,ReceivedAtUtc=now())
        db.insert("warehouse.HandlingUnitItem",HandlingUnitId=hu,ReceiptId=receipt,BaseQuantity=take,OperationId=operation,PackedBy=ctx["actor"])
        remaining-=take
        if remaining==0: break
    if remaining: raise BusinessError("La disponibilidad cambió. Actualiza e intenta de nuevo.")
    return dict(message=f"Tarima {code} creada con {qty} piezas.",hu_id=hu)

def stage(db,ctx,payload,operation):
    hu=next((r for r in db.rows(HU_SQL) if r["id"]==payload["id"]),None)
    if not hu or hu["estado"]!="PACKED": raise BusinessError("La tarima debe estar empacada.")
    db.insert("warehouse.HandlingUnitMovement",HandlingUnitId=hu["id"],FromLocationId=ctx["locations"]["PACKING"],
              ToLocationId=ctx["locations"]["STAGING"],ActorUserId=ctx["actor"],OperationId=operation,
              MovedAtUtc=now(),Reason="Preembarque de demostración")
    db.execute("UPDATE warehouse.HandlingUnit SET Status='STAGED',CurrentLocationId=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",ctx["locations"]["STAGING"],hu["id"])
    return dict(message="Tarima disponible en preembarque.")

def incident(db,ctx,payload,operation):
    line=required(db,LINE_SQL+" WHERE l.Id=?",payload["id"])
    reason=str(payload.get("reason","")).strip()
    if not 5<=len(reason)<=1000: raise BusinessError("Describe la incidencia con entre 5 y 1000 caracteres.")
    ident=db.insert("quality.Incident",TypeId=db.scalar("SELECT Id FROM quality.IncidentType WHERE Code='DEMO-INC'"),
                    OrderLineId=line["id"],ReportedBy=ctx["actor"],Severity="WARNING",Status="OPEN",Description=reason)
    db.insert("quality.IncidentAction",IncidentId=ident,ActorUserId=ctx["actor"],ActionCode="REPORTED",
              Comment=reason,OperationId=operation)
    return dict(message="Incidencia registrada; no modifica cantidades ni bloquea automáticamente.",incident_id=ident)
