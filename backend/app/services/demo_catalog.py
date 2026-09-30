"""Small destination catalog and friendly order entry for the local demo."""
from datetime import date
from decimal import Decimal, InvalidOperation
from uuid import uuid4
import csv
import io
from backend.app.repositories.demo import BusinessError, now

DISTANCE_SOURCE = "DEMO: kilómetros capturados desde el almacén"

DESTINATIONS_SQL = """
SELECT ds.Id AS id,ds.Code AS codigo,ds.Name AS nombre,ds.CustomerId AS customer_id,
 c.Code AS cliente_codigo,pa.Id AS address_id,dr.Id AS distance_id,dr.RoadDistanceKm AS km
FROM catalog.DeliverySite ds
JOIN catalog.Customer c ON c.Id=ds.CustomerId
CROSS APPLY (SELECT TOP(1) Id FROM catalog.PointAddress WHERE PointId=ds.PointId ORDER BY VersionNumber DESC) pa
OUTER APPLY (SELECT TOP(1) dr.Id,dr.RoadDistanceKm FROM planning.DistanceReference dr
 JOIN catalog.PointAddress orig ON orig.Id=dr.OriginAddressId
 JOIN catalog.Warehouse w ON w.PointId=orig.PointId AND w.Code='DEMO-ALM'
 WHERE dr.DestinationAddressId=pa.Id AND dr.SourceDescription LIKE 'DEMO: kilómetros capturados%'
 AND (dr.ValidUntil IS NULL OR dr.ValidUntil>=CAST(GETDATE() AS date)) ORDER BY dr.Id DESC) dr
WHERE ds.Code LIKE 'DEMO-%' AND ds.IsActive=1 AND c.IsActive=1 ORDER BY ds.Name,ds.Id
"""

def destinations(db):
    return db.rows(DESTINATIONS_SQL)

def origin_address(db):
    return db.scalar("""SELECT TOP(1) pa.Id FROM catalog.PointAddress pa JOIN catalog.Warehouse w
 ON w.PointId=pa.PointId WHERE w.Code='DEMO-ALM' ORDER BY pa.VersionNumber DESC""")

def distance_value(value):
    try:
        km=Decimal(str(value))
        if not km.is_finite() or km<=0 or km>100000 or km.as_tuple().exponent < -3:
            raise ValueError()
        return km
    except (ValueError,InvalidOperation):
        raise BusinessError("Indica kilómetros mayores que cero, hasta 100,000, con máximo 3 decimales.") from None

def record_distance(db,address,km):
    return db.insert("planning.DistanceReference",OriginAddressId=origin_address(db),
        DestinationAddressId=address,RoadDistanceKm=km,MeasuredOn=date.today(),
        SourceDescription=DISTANCE_SOURCE+" · "+uuid4().hex)

def save_destination(db,ctx,payload,operation):
    name=str(payload.get("name","")).strip()
    if not 2<=len(name)<=120:
        raise BusinessError("Escribe un nombre de tienda de 2 a 120 caracteres.")
    km=distance_value(payload.get("km"))
    ident=payload.get("id")
    existing=next((r for r in destinations(db) if r["id"]==ident),None)
    if ident is not None and not existing:
        raise BusinessError("El destino no existe en esta demostración.")
    duplicate=db.one("SELECT Id FROM catalog.DeliverySite WHERE Code LIKE 'DEMO-%' AND Name=? AND Id<>?",name,ident or 0)
    if duplicate:
        raise BusinessError("Ya existe un destino con ese nombre. Selecciónalo para cambiar sus kilómetros.")
    if existing:
        db.execute("UPDATE catalog.DeliverySite SET Name=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",name,ident)
        address=existing["address_id"]
    else:
        code="DEMO-DEST-"+uuid4().hex[:12].upper()
        customer=db.scalar("SELECT Id FROM catalog.Customer WHERE Code='DEMO-CLI-A'")
        point=db.insert("catalog.LogisticsPoint",Code=code,Name=name,PointType="DELIVERY_SITE",IsActive=True)
        address=db.insert("catalog.PointAddress",PointId=point,VersionNumber=1,
            AddressText="Destino de prueba registrado por nombre; dirección pendiente",
            City="Pendiente de captura",CountryCode="MX",TimeZoneId="America/Monterrey",ValidFromUtc=now())
        ident=db.insert("catalog.DeliverySite",CustomerId=customer,Code=code,Name=name,PointId=point,IsActive=True)
    record_distance(db,address,km)
    return dict(message=f"{name}: {km} km desde el almacén. Guardado.",destination_id=ident)

def route_for_units(db,units):
    catalog={r["id"]:r for r in destinations(db)}
    result=[]
    for ident in {u["DeliverySiteId"] for u in units}:
        row=catalog.get(ident)
        if not row or row["km"] is None:
            raise BusinessError("Registra los kilómetros de todos los destinos antes de crear el viaje.")
        result.append(row)
    return sorted(result,key=lambda r:(r["km"],r["nombre"].casefold(),r["id"]))

def create_order(db,ctx,payload,operation):
    from backend.app.services.demo_import import import_orders
    from backend.app.services.demo_seed import HEADERS
    from backend.app.services.demo_warehouse import quantity
    product=db.one("SELECT Id,Code FROM catalog.Material WHERE Id=? AND Code LIKE 'DEMO-%' AND IsActive=1",payload.get("product_id"))
    dest=next((r for r in destinations(db) if r["id"]==payload.get("destination_id")),None)
    if not product or not dest:
        raise BusinessError("Selecciona un producto y una tienda del catálogo.")
    qty=quantity(payload)
    if qty>100000: raise BusinessError("Usa un máximo de 100,000 piezas por pedido de prueba.")
    try: due=date.fromisoformat(str(payload.get("due_date","")))
    except ValueError: raise BusinessError("Selecciona una fecha de entrega válida.") from None
    order="DEMO-"+uuid4().hex[:12].upper()
    stream=io.StringIO(newline="")
    writer=csv.writer(stream)
    writer.writerow(HEADERS)
    writer.writerow([order,"10",dest["cliente_codigo"],dest["codigo"],product["Code"],str(qty),"PZA",due.isoformat()])
    result=import_orders(db,ctx,dict(content=stream.getvalue(),filename=order+".csv"),operation)
    result["message"]="Pedido de prueba guardado desde CSV: "+order
    return result
