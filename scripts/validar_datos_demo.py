
"""Read-only checks of fictional design fixtures, not a production importer.

Run from any directory with Python 3.14. No SQL, network, .env or dependencies.
"""
from __future__ import annotations
import csv
import hashlib
import io
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SAMPLES = ROOT / "samples"
CHECKS = 0

def require(condition: bool, message: str) -> None:
    global CHECKS
    CHECKS += 1
    if not condition:
        raise ValueError(message)

def quantity(value: str) -> Decimal:
    result = Decimal(value)
    require(result.is_finite() and result > 0, f"Cantidad inválida: {value}")
    return result

def index(records: list[dict], key: str = "code") -> dict:
    result = {row[key]: row for row in records}
    require(len(result) == len(records), f"Identificadores repetidos: {key}")
    return result

def read_fixture(path: Path, profile: dict) -> tuple[list[dict], list[str]]:
    if path.stat().st_size == 0:
        return [], ["EMPTY_FILE"]
    delimiter = profile["txt_delimiter"] if path.suffix == ".txt" else profile["csv_delimiter"]
    reader = csv.DictReader(io.StringIO(path.read_text(encoding=profile["encoding"])), delimiter=delimiter)
    if not set(profile["required_columns"]) <= set(reader.fieldnames or []):
        return [], ["MISSING_COLUMNS"]
    return list(reader), []

def validate_rows(rows: list[dict], demo: dict) -> list[str]:
    materials = {r["code"]: r for r in demo["materials"]}
    sites = {r["code"]: r for r in demo["destinations"]}
    customers = {r["code"] for r in demo["customers"]}
    units = {r["code"]: r for r in demo["units"]}
    errors: list[str] = []
    seen: set[tuple[str, str]] = set()
    for row in rows:
        key = (row["NumeroPedido"], row["NumeroLinea"])
        if key in seen:
            errors.append("DUPLICATE_LINE")
        seen.add(key)
        if not all(key):
            errors.append("MISSING_ORDER_OR_LINE")
        if not row["Material"]:
            errors.append("MISSING_MATERIAL")
        elif row["Material"] not in materials:
            errors.append("UNKNOWN_MATERIAL")
        if row["Cliente"] not in customers:
            errors.append("UNKNOWN_CUSTOMER")
        site = sites.get(row["Destino"])
        if site is None:
            errors.append("UNKNOWN_DESTINATION")
        elif site["customer"] != row["Cliente"]:
            errors.append("DESTINATION_CUSTOMER_MISMATCH")
        unit = units.get(row["UnidadMedida"])
        if unit is None:
            errors.append("UNKNOWN_UNIT")
        try:
            value = Decimal(row["Cantidad"])
            if not value.is_finite():
                errors.append("INVALID_QUANTITY")
            elif value <= 0:
                errors.append("NON_POSITIVE_QUANTITY")
            elif unit and value != value.quantize(Decimal(1).scaleb(-unit["quantity_scale"])):
                errors.append("INVALID_QUANTITY_SCALE")
        except InvalidOperation:
            errors.append("INVALID_QUANTITY")
        try:
            if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", row["FechaEntregaSolicitada"]):
                raise ValueError("Formato")
            date.fromisoformat(row["FechaEntregaSolicitada"])
        except ValueError:
            errors.append("INVALID_DATE")
    return errors

def check_scenario(demo: dict) -> list[dict]:
    require(demo["metadata"]["fictional"] is True, "Debe estar marcado como ficticio.")
    require(demo["metadata"]["not_sql_seed"] is True, "Formato simplificado, no semilla SQL.")
    warehouses = index(demo["warehouses"])
    locations = index(demo["locations"])
    customers = index(demo["customers"])
    sites = index(demo["destinations"])
    materials = index(demo["materials"])
    lots = index(demo["lots"])
    for loc in locations.values():
        require(loc["warehouse"] in warehouses, "Almacén desconocido de ubicación.")
    for site in sites.values():
        require(site["customer"] in customers, "Cliente desconocido de destino.")
    for lot in lots.values():
        require(lot["material"] in materials, "Material desconocido de lote.")
    orders = {(r["NumeroPedido"], r["NumeroLinea"]): r for r in demo["orders"]}
    require(len(orders) == len(demo["orders"]), "Identidad de línea duplicada.")
    require(not validate_rows(demo["orders"], demo), "Pedidos del escenario inválidos.")
    allocations = index(demo["allocations"])
    allocated: dict[tuple, Decimal] = defaultdict(Decimal)
    for a in allocations.values():
        key = (a["order"], a["line"])
        require(key in orders, "Asignación sin pedido/línea.")
        require(a["warehouse"] in warehouses, "Almacén desconocido en asignación.")
        loc = locations[a["source_location"]]
        require(loc["warehouse"] == a["warehouse"] and loc["type"] == "BIN", "Origen incompatible.")
        require(lots[a["lot"]]["material"] == orders[key]["Material"], "Lote/material incompatibles.")
        allocated[key] += quantity(a["quantity"])
    for key, order in orders.items():
        require(allocated[key] == quantity(order["Cantidad"]), "El plan de demostración no cubre la demanda.")
    tasks = index(demo["picking_lines"])
    planned: dict[str, Decimal] = defaultdict(Decimal)
    for task in tasks.values():
        require(task["allocation"] in allocations, "Tarea sin asignación.")
        planned[task["allocation"]] += quantity(task["planned_quantity"])
    for key, total in planned.items():
        require(total <= quantity(allocations[key]["quantity"]), "Picking planeado excede asignación.")
    def task_allocation(task_code: str) -> dict:
        return allocations[tasks[task_code]["allocation"]]
    def order_key(a: dict) -> tuple[str, str]:
        return a["order"], a["line"]
    confirmations = index(demo["pick_confirmations"])
    command_keys = [c["command_key"] for c in confirmations.values()]
    require(len(command_keys) == len(set(command_keys)), "Claves de demostración repetidas.")
    picked: dict[str, Decimal] = defaultdict(Decimal)
    for c in confirmations.values():
        require(c["picking_line"] in tasks, "Confirmación sin tarea.")
        picked[c["picking_line"]] += quantity(c["quantity"])
    for key, total in picked.items():
        require(total <= quantity(tasks[key]["planned_quantity"]), "Picking excede lo planeado.")
    receipts = index(demo["packing_receipts"])
    received: dict[str, Decimal] = defaultdict(Decimal)
    for receipt in receipts.values():
        require(receipt["confirmation"] in confirmations, "Recepción sin confirmación.")
        conf = confirmations[receipt["confirmation"]]
        a = task_allocation(conf["picking_line"])
        loc = locations[receipt["packing_location"]]
        require(loc["warehouse"] == a["warehouse"] and loc["type"] == "PACKING", "Puesto Packing incompatible.")
        received[receipt["confirmation"]] += quantity(receipt["quantity"])
    for key, total in received.items():
        require(total <= quantity(confirmations[key]["quantity"]), "Recepción excesiva.")
    hus = index(demo["handling_units"])
    items = index(demo["hu_items"])
    packed: dict[str, Decimal] = defaultdict(Decimal)
    hu_contents: dict[str, dict[str, Decimal]] = defaultdict(lambda: defaultdict(Decimal))
    def item_allocation(item: dict) -> dict:
        receipt = receipts[item["receipt"]]
        conf = confirmations[receipt["confirmation"]]
        return task_allocation(conf["picking_line"])
    for item in items.values():
        require(item["receipt"] in receipts and item["hu"] in hus, "Contenido sin HU/recepción.")
        hu = hus[item["hu"]]
        a = item_allocation(item)
        order = orders[order_key(a)]
        require(hu["warehouse"] == a["warehouse"], "HU de otro almacén.")
        require(hu["destination"] == order["Destino"], "HU con destino incompatible.")
        q = quantity(item["quantity"])
        packed[item["receipt"]] += q
        hu_contents[item["hu"]][a["code"]] += q
    for key, total in packed.items():
        require(total <= quantity(receipts[key]["quantity"]), "Packing excede recepción.")
    for code, hu in hus.items():
        require(bool(hu_contents[code]), "HU de ejemplo vacía.")
        require(hu["status"] == "SHIPPED" and hu["current_location"] is None, "Estado esperado de HU incoherente.")
    trips = index(demo["trips"])
    stops = {}
    for trip in trips.values():
        require(trip["warehouse"] in warehouses, "Origen de viaje desconocido.")
        require([s["sequence"] for s in trip["stops"]] == list(range(1, len(trip["stops"])+1)), "Secuencia inválida.")
        for stop in trip["stops"]:
            require(stop["code"] not in stops, "Parada repetida.")
            require(stop["destination"] in sites, "Destino de parada desconocido.")
            require(Decimal(stop["reference_km_from_previous"]) >= 0, "Distancia negativa.")
            stops[stop["code"]] = (trip, stop)
    commitments: dict[tuple[str, str], Decimal] = {}
    by_allocation: dict[str, Decimal] = defaultdict(Decimal)
    for row in demo["trip_allocations"]:
        key = row["allocation"], row["stop"]
        require(key not in commitments, "Compromiso asignación/parada duplicado.")
        a = allocations[row["allocation"]]
        trip, stop = stops[row["stop"]]
        require(trip["warehouse"] == a["warehouse"], "Viaje sale de otro almacén.")
        require(stop["destination"] == orders[order_key(a)]["Destino"], "Parada de otro destino.")
        q = quantity(row["quantity"])
        commitments[key] = q
        by_allocation[a["code"]] += q
    for key, total in by_allocation.items():
        require(total <= quantity(allocations[key]["quantity"]), "Cantidad comprometida en exceso.")
    shipments = index(demo["shipments"])
    hu_assignments = {}
    committed_hu: dict[tuple, Decimal] = defaultdict(Decimal)
    for row in demo["shipment_units"]:
        require(row["hu"] not in hu_assignments, "HU asignada dos veces.")
        require(row["hu"] in hus and row["shipment"] in shipments, "Asignación sin HU/embarque.")
        shipment = shipments[row["shipment"]]
        trip, stop = stops[row["stop"]]
        require(shipment["trip"] == trip["code"], "Parada fuera del viaje.")
        hu = hus[row["hu"]]
        require(hu["destination"] == stop["destination"], "Destino de HU no coincide.")
        require(hu["warehouse"] == trip["warehouse"], "Almacén de HU no coincide.")
        require(row["status"] == "DISPATCHED", "Estado de asignación inesperado.")
        for a, q in hu_contents[row["hu"]].items():
            committed_hu[(a, row["stop"])] += q
        hu_assignments[row["hu"]] = row
    for key, total in committed_hu.items():
        require(key in commitments and total <= commitments[key], "Carga supera el compromiso de la parada.")
    loaded = set()
    last_stop: dict[str, int] = {}
    for event in demo["load_events"]:
        assignment = hu_assignments[event["hu"]]
        require(event["hu"] not in loaded, "Carga duplicada.")
        require(event["type"] == "LOAD", "Esta muestra solo contiene carga.")
        require(event["shipment"] == assignment["shipment"], "Carga en embarque incorrecto.")
        sequence = stops[assignment["stop"]][1]["sequence"]
        require(sequence <= last_stop.get(event["shipment"], sequence), "Carga fuera del orden inverso.")
        last_stop[event["shipment"]] = sequence
        loaded.add(event["hu"])
    require(loaded == set(hu_assignments) == set(hus), "Cierre con HU sin cargar.")
    for shipment in shipments.values():
        require(shipment["status"] == "CLOSED", "El primer embarque debe estar cerrado.")
        require(trips[shipment["trip"]]["status"] == "CLOSED", "Estado de viaje inconsistente.")
    stages: dict[tuple, dict[str, Decimal]] = defaultdict(lambda: defaultdict(Decimal))
    for c in confirmations.values():
        stages[order_key(task_allocation(c["picking_line"]))]["picked"] += quantity(c["quantity"])
    for r in receipts.values():
        a = task_allocation(confirmations[r["confirmation"]]["picking_line"])
        stages[order_key(a)]["received"] += quantity(r["quantity"])
    for item in items.values():
        key = order_key(item_allocation(item))
        stages[key]["packed"] += quantity(item["quantity"])
        if item["hu"] in loaded:
            stages[key]["shipped"] += quantity(item["quantity"])
    actual = []
    for key, row in orders.items():
        value = {"order":key[0], "line":key[1], "requested":str(quantity(row["Cantidad"]))}
        value.update({s:str(stages[key][s]) for s in ["picked","received","packed","shipped"]})
        value["pending_shipping"] = str(quantity(row["Cantidad"])-stages[key]["shipped"])
        actual.append(value)
    require(actual == demo["expected_line_progress"], "Avance calculado distinto al esperado.")
    return actual

def main() -> int:
    try:
        demo = json.loads((SAMPLES/"scenarios/demo_logistica.json").read_text(encoding="utf-8"))
        manifest = json.loads((SAMPLES/"scenarios/manifest.json").read_text(encoding="utf-8"))
        progress = check_scenario(demo)
        for fixture in manifest["fixtures"]:
            rows, errors = read_fixture(SAMPLES/fixture["path"], manifest["profile"])
            if not errors:
                errors = validate_rows(rows, demo)
            require(Counter(errors) == Counter(fixture["expected_validation_errors"]), "Errores inesperados en "+fixture["path"]+": "+str(errors))
        a, b = [SAMPLES/p for p in manifest["duplicate_content_pair"]]
        require(hashlib.sha256(a.read_bytes()).digest() == hashlib.sha256(b.read_bytes()).digest(), "El duplicado debe ser idéntico en bytes.")
        valid, _ = read_fixture(SAMPLES/"csv/pedidos_correctos.csv", manifest["profile"])
        txt, _ = read_fixture(SAMPLES/"txt/pedidos.txt", manifest["profile"])
        require(valid == txt == demo["orders"], "CSV, TXT y escenario difieren.")
        zeros, _ = read_fixture(SAMPLES/"csv/pedidos_codigos_con_ceros.csv", manifest["profile"])
        require(zeros[0]["NumeroPedido"] == "000450004" and zeros[0]["NumeroLinea"] == "000010", "Se perdieron ceros iniciales.")
        updated, _ = read_fixture(SAMPLES/manifest["update_requires_review"], manifest["profile"])
        require(updated[0]["Cantidad"] == "120" and valid[0]["Cantidad"] == "100", "Muestra de actualización incorrecta.")
        print(f"OK: {CHECKS} comprobaciones de muestras; {len(manifest['fixtures'])} archivos.")
        print("Son datos ficticios y un escenario esperado. No se conectó a SQL Server ni se probó la aplicación.")
        for row in progress:
            print(f"Pedido {row['order']} línea {row['line']}: {row['shipped']}/{row['requested']} embarcadas; pendiente {row['pending_shipping']}.")
        return 0
    except (ValueError, KeyError, OSError, InvalidOperation) as exc:
        print(f"ERROR en datos de prueba: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
