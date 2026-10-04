"""Read-only daily workload, deliberately separate from physical stock and presence."""
from datetime import date, datetime, timezone, timedelta
import json


DEMO_ZONE = timezone(timedelta(hours=-6), "Ciudad de México")


def supervisor_view(state: dict, day: date | None = None, now: datetime | None = None) -> dict:
    # Demo calendar: Mexico City in 2026 (UTC-06); independent of the host clock zone.
    local_now = (now or datetime.now(timezone.utc)).astimezone(DEMO_ZONE)
    day = day or local_now.date()
    key = day.isoformat()
    active = [t for t in state["tasks"] if t.get("estado") != "CANCELLED"]
    today = [t for t in active if str(t["fecha"])[:10] == key]
    overdue = [t for t in active if str(t["fecha"])[:10] < key and t["cantidad"] > t["empacado"]]
    rows = []
    for t in active:
        pending = max(0, t["cantidad"] - t["empacado"])
        ready = max(0, t["recogido"] - t["empacado"])
        rows.append(dict(t, por_recoger=max(0, t["cantidad"]-t["recogido"]),
                         listo_empacar=ready, pendiente=pending,
                         responsable=t.get("responsable") or "Sin asignar",
                         situacion="Empacado" if not pending else "Listo para empacar" if ready else "Recoger producto",
                         periodo="Atraso" if str(t["fecha"])[:10] < key else "Hoy" if str(t["fecha"])[:10] == key else "Próximo"))
    rows.sort(key=lambda t: (t["pendiente"] == 0, t["periodo"] != "Atraso", t["listo_empacar"] == 0, str(t["fecha"])))
    workload = today + overdue
    metrics = dict(programado=sum(t["cantidad"] for t in today),
                   empacado=sum(t["empacado"] for t in today),
                   recoger=sum(max(0,t["cantidad"]-t["recogido"]) for t in workload),
                   listo=sum(max(0,t["recogido"]-t["empacado"]) for t in workload),
                   atraso=sum(max(0,t["cantidad"]-t["empacado"]) for t in overdue))
    capacity = [d for d in state["days"] if str(d["fecha"])[:10] == key]
    unplanned = sum(max(0,l["cantidad"]-l.get("planeado",0)) for l in state["lines"]
                    if str(l["fecha"])[:10] <= key)
    actions = {"PICK":"Recogida confirmada", "PACK":"Empaque confirmado",
               "STAGE":"Material en preembarque", "LOAD":"Carga confirmada", "CLOSE":"Embarque cerrado",
               "INCIDENT":"Incidencia registrada"}
    activity = []
    for event in state.get("operational_audit", state.get("audit", [])):
        if event["accion"] not in actions:
            continue
        stamp = event["fecha"]
        if isinstance(stamp,str):
            stamp = datetime.fromisoformat(stamp.replace("Z","+00:00"))
        if stamp.tzinfo is None:
            stamp = stamp.replace(tzinfo=timezone.utc)
        local = stamp.astimezone(DEMO_ZONE)
        try:
            detail = json.loads(event.get("detalle") or "{}")
        except (TypeError,ValueError):
            detail = {}
        activity.append(dict(fecha=local.isoformat(),hora=local.strftime("%d/%m %H:%M"), accion=actions[event["accion"]],
                             responsable=event.get("responsable") or "Usuario demo",
                             detalle=detail.get("message",actions[event["accion"]])))
    units=state.get("units",[])
    handoffs=dict(
        to_stage=sum(1 for u in units if u["estado"]=="PACKED"),
        waiting_trip=sum(1 for u in units if u["estado"]=="STAGED" and u.get("shipment_id") is None),
        to_load=sum(1 for u in units if u["estado"]=="STAGED" and u.get("shipment_id") is not None))
    return dict(handoffs=handoffs,fecha=key, actualizado=local_now.isoformat(), metrics=metrics, tasks=[r for r in rows if str(r['fecha'])[:10]<=key], all_tasks=rows,
                sin_programar=unplanned, activity=activity[:8], inventory_known=False,
                capacidad=sum(d["capacidad"] for d in capacity) if capacity else None,
                reservado=sum(d["reservado"] for d in capacity))
