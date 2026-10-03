"""Choose a single operational instruction. No import/planning decisions on the client."""
from typing import Any


def location_check_digit(code: str) -> str:
    """Deterministic 2-digit verifier derived from the location code.

    In production this value is printed on the physical rack label so the
    operator can enter it manually when the camera cannot read the barcode
    (damaged label, poor lighting, etc.).

    Algorithm: weighted sum of ASCII values modulo 100.
    Examples: R01-A01 → "61",  R01-A04 → "82",  R03-B02 → "79"
    """
    if not code:
        return "00"
    val = sum(ord(c) * (i + 1) for i, c in enumerate(code))
    return f"{val % 100:02d}"


def operator_view(state: dict, preferred_allocation: int | None = None) -> dict:
    locations={r["kind"]:r for r in state.get("locations",[])}
    tasks=sorted([t for t in state["tasks"] if t["estado"]!="CANCELLED"],key=lambda t:(str(t["fecha"]),t["id"]))
    units=state["units"]
    shipments={s["id"]:s for s in state["shipments"] if s["estado"] in ("OPEN","LOADING")}

    def place(row: dict) -> str:
        return f'{row["almacen"]} · {row["ubicacion_nombre"]} ({row["ubicacion"]})'

    def target(kind: str) -> str | None:
        row=locations.get(kind)
        return f'{row["almacen"]} · {row["nombre"]} ({row["codigo"]})' if row else None

    def instruction(action: str, row: dict, qty: Any, destination: str, step: int) -> dict:
        payload=dict(id=row["id"])
        if action in ("pick","pack"):payload["quantity"]=int(qty)
        if action=="pick":payload.update(location=row["ubicacion"],material=row["material"])
        if action=="load":payload["code"]=row["codigo"]
        # Scan verification: only picking requires location confirmation.
        scan_code = row["ubicacion"] if action == "pick" else None
        return dict(action=action,payload=payload,quantity=int(qty),product=row["descripcion"],
            source=place(row),destination=destination,store=row["destino"],
            allocation_id=row["AllocationId"],line_id=row["line_id"],step=step,
            order=row["pedido"],scheduled_date=str(row.get("fecha","")),
            hu=row.get("codigo"),can_adjust=action in ("pick","pack"),
            expected_scan=scan_code,
            check_digit=location_check_digit(scan_code) if scan_code else None)

    loading=[]
    for sid,shipment in shipments.items():
        pending=sorted([u for u in units if u["shipment_id"]==sid and u["estado"]=="STAGED"],
                       key=lambda u:(-u["parada"],u["id"]))
        if pending:
            row=pending[0]
            loading.append(instruction("load",row,row["cantidad"],f'{shipment["anden"]} · Tráiler {shipment["trailer"]}',4))

    def preparation(task: dict) -> dict | None:
        packed=sorted([u for u in units if u["AllocationId"]==task["AllocationId"] and u["estado"]=="PACKED"],key=lambda u:u["id"])
        if packed and target("STAGING"):
            return instruction("stage",packed[0],packed[0]["cantidad"],target("STAGING"),3)
        if task["recogido"]>task["empacado"] and target("PACKING"):
            return instruction("pack",task,task["recogido"]-task["empacado"],target("PACKING"),2)
        if task["cantidad"]>task["recogido"] and target("PACKING"):
            return instruction("pick",task,task["cantidad"]-task["recogido"],target("PACKING"),1)
        return None

    preparing=[i for t in tasks if (i:=preparation(t)) is not None]
    # Keep the picked product through packing/staging, even when other work is waiting.
    selected=next((i for i in preparing if i["allocation_id"]==preferred_allocation),None)
    if selected is None:selected=next(iter(loading+preparing),None)
    if selected:
        return dict(task=selected,pending=len(loading)+len(preparing),message="",demo=True)
    totals=state["totals"]
    if any(t["cantidad"]>t["empacado"] for t in tasks) or any(u["estado"]=="PACKED" for u in units):
        message="Falta configurar el área de empaque o salida. Avisa al supervisor."
    elif totals["planeado"]<totals["cantidad"]:
        message="Hay pedidos por organizar. El supervisor debe liberar las tareas."
    elif any(u["estado"]=="STAGED" and u["shipment_id"] is None for u in units):
        message="El material está en el área de salida. Espera a que el supervisor prepare el viaje."
    elif shipments:
        message="La carga está terminada. El supervisor puede cerrar el embarque."
    else:
        message="No tienes tareas pendientes. Espera la siguiente asignación."
    return dict(task=None,pending=0,message=message,demo=True)
