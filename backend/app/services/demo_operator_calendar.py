"""Operator calendar: today is actionable, future dates are read-only."""
from datetime import date, datetime
from backend.app.services.demo_supervisor import DEMO_ZONE
from backend.app.services.demo_operator import operator_view
from backend.app.repositories.demo import BusinessError

def today_local():
    return datetime.now(DEMO_ZONE).date()

def calendar_view(state, selected=None, preferred=None, today=None):
    today=today or today_local()
    selected=selected or today
    if selected<today:
        raise BusinessError("No puedes seleccionar días anteriores. Los pendientes anteriores aparecen hoy.")
    future=selected>today
    tasks=[t for t in state["tasks"] if (str(t["fecha"])[:10]==selected.isoformat() if future else str(t["fecha"])[:10]<=today.isoformat())]
    allocations={t["AllocationId"] for t in tasks}
    units=[u for u in state["units"] if u["AllocationId"] in allocations]
    preview=[dict(id_pedido=t.get("id_pedido",t["pedido"]),product=t["descripcion"],quantity=max(0,t["cantidad"]-t["empacado"]),
                  store=t["destino"],source=t["almacen"]+" · "+t["ubicacion_nombre"])
             for t in tasks if t["estado"]!="CANCELLED"]
    if future:
        result=dict(task=None,pending=len(preview),message="Solo consulta: las tareas futuras no se pueden confirmar.",demo=True)
    else:
        result=operator_view(dict(state,tasks=tasks,units=units),preferred)
    result.update(today=today.isoformat(),selected_date=selected.isoformat(),read_only=future,preview=preview)
    return result

def validate_operator_day(db,action,payload):
    from backend.app.repositories.demo_queries import TASK_SQL,HU_SQL
    today=today_local()
    if payload.get("operator_date")!=today.isoformat():
        raise BusinessError("Solo puedes confirmar desde el día de hoy. Actualiza el calendario.")
    if action not in ("pick","pack","stage","load","incident"):
        raise BusinessError("Acción no disponible para el operador.")
    if action in ("pick","pack"):
        tasks=db.rows(TASK_SQL+" WHERE tl.Id=?",payload["id"])
    elif action=="incident":
        tasks=db.rows(TASK_SQL+" WHERE l.Id=?",payload["id"])
    else:
        units=[u for u in db.rows(HU_SQL) if u["id"]==payload["id"]]
        tasks=db.rows(TASK_SQL+" WHERE fa.Id=?",units[0]["AllocationId"]) if units else []
    if not tasks or not any(t["fecha"]<=today for t in tasks):
        raise BusinessError("Esta tarea pertenece a una fecha futura o no está disponible.")
