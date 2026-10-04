"""Strict, independent parser for the explicitly documented demonstration contract."""
import csv
from datetime import date
from decimal import Decimal, InvalidOperation
import io
from backend.app.services.demo_seed import HEADERS

def parse_csv(content: str, delimiter: str = ","):
    errors=[]
    rows=[]
    if len(content.encode("utf-8"))>1_000_000:
        return [],[dict(line=0,message="Máximo 1 MB por archivo de demostración.")]
    reader=csv.DictReader(io.StringIO(content.lstrip("\ufeff"),newline=""),delimiter=delimiter)
    if not reader.fieldnames or any(h not in reader.fieldnames for h in HEADERS):
        return [],[dict(line=1,message="Faltan columnas: "+", ".join(h for h in HEADERS if not reader.fieldnames or h not in reader.fieldnames))]
    if len(set(reader.fieldnames))!=len(reader.fieldnames):
        return [],[dict(line=1,message="Hay encabezados duplicados.")]
    seen=set()
    try:
        for index,row in enumerate(reader,2):
            if index>501:
                errors.append(dict(line=index,message="Máximo 500 filas.")); break
            normalized={h:(row.get(h) or "").strip() for h in HEADERS}
            for h in ("ID","Producto","QuienPidio","Destino","Almacen"):
                if h in row:normalized[h]=(row[h] or "").strip()
            problems=[]
            if "ID" in row and not normalized["ID"]:
                problems.append("ID no puede estar vacío")
            if None in row or any(row.get(h) is None for h in HEADERS):
                problems.append("Número de columnas inconsistente")
            if any(not normalized[h] for h in HEADERS):
                problems.append("Todos los campos del contrato son obligatorios")
            if any(len(v)>100 for v in normalized.values()):
                problems.append("Un campo excede 100 caracteres")
            key=(normalized["NumeroPedido"],normalized["LineaPedido"])
            if key in seen: problems.append("Pedido y línea duplicados")
            seen.add(key)
            try:
                qty=Decimal(normalized["CantidadSolicitada"])
                if not qty.is_finite() or qty<=0 or qty!=qty.to_integral_value() or qty>100000:
                    raise InvalidOperation
            except InvalidOperation:
                problems.append("Cantidad debe ser un entero entre 1 y 100000")
            try:
                date.fromisoformat(normalized["FechaRequeridaEntrega"])
            except ValueError:
                problems.append("Fecha debe usar YYYY-MM-DD")
            if normalized["UnidadMedida"]!="PZA": problems.append("La demo admite solamente PZA")
            if not normalized["NumeroPedido"].startswith("DEMO-"):
                problems.append("Los pedidos de prueba deben comenzar por DEMO-")
            for problem in problems: errors.append(dict(line=reader.line_num,message=problem))
            rows.append(dict(number=reader.line_num,data=normalized))
    except csv.Error:
        errors.append(dict(line=reader.line_num,message="Archivo delimitado mal formado"))
    if not rows and not errors: errors.append(dict(line=2,message="El archivo no tiene pedidos"))
    return rows,errors
