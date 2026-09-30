"""Only explicitly prefixed, fictional catalog data; existing records are preserved."""
import hashlib
from backend.app.repositories.demo import now, dump, transaction

SOURCE = "DEMO_DESKTOP"
HEADERS = ["NumeroPedido","LineaPedido","CodigoCliente","CodigoDestino","CodigoMaterial",
           "CantidadSolicitada","UnidadMedida","FechaRequeridaEntrega"]

def ensure(db, table, key, value, **values):
    row = db.one(f"SELECT Id FROM {table} WHERE [{key}]=?", value)
    return row["Id"] if row else db.insert(table, **{key:value}, **values)

def seed(db):
    actor = ensure(db,"security.AppUser","Login","demo.desktop",DisplayName="Coordinador · DEMO",
                   PasswordHash="!LOCAL_TOKEN_ONLY",IsActive=True,FailedLoginCount=0)
    source = ensure(db,"integration.SourceSystem","Code",SOURCE,Description="Simulación de escritorio, sin conexión SAP",IsActive=True)
    profile = db.one("SELECT Id FROM integration.MappingProfileVersion WHERE SourceSystemId=? AND ProfileCode='DEMO_CSV' AND VersionNumber=1",source)
    if not profile:
        pid = db.insert("integration.MappingProfileVersion",SourceSystemId=source,ProfileCode="DEMO_CSV",VersionNumber=1,
                        Delimiter=",",EncodingName="utf-8-sig",HasHeader=True,DateFormat="yyyy-MM-dd",
                        DecimalSeparator=".",SourceTimeZone="America/Monterrey",Mode="ORDER_SNAPSHOT",
                        DefinitionHash=hashlib.sha256(dump(HEADERS).encode()).digest())
        for h in HEADERS:
            db.insert("integration.MappingField",ProfileVersionId=pid,TargetField=h,SourceColumnName=h,IsRequired=True)
    else:
        pid=profile["Id"]
    unit=db.scalar("SELECT Id FROM catalog.UnitOfMeasure WHERE Code='PZA'")
    point=ensure(db,"catalog.LogisticsPoint","Code","DEMO-ALM",Name="Almacén Monterrey · DEMO",PointType="WAREHOUSE",IsActive=True)
    if not db.one("SELECT Id FROM catalog.PointAddress WHERE PointId=?",point):
        db.insert("catalog.PointAddress",PointId=point,VersionNumber=1,AddressText="Dirección ficticia de almacén",
                  City="Monterrey",CountryCode="MX",TimeZoneId="America/Monterrey",ValidFromUtc=now())
    wh=ensure(db,"catalog.Warehouse","Code","DEMO-ALM",Name="Monterrey · DEMO",PointId=point,IsActive=True)
    locations={}
    for code,name,kind in [("DEMO-R01","Rack de surtido","BIN"),("DEMO-PACK","Mesa de empaque","PACKING"),("DEMO-STG","Preembarque","STAGING"),("DEMO-DOCK","Andén 01","DOCK")]:
        loc=db.one("SELECT Id FROM catalog.Location WHERE WarehouseId=? AND Code=?",wh,code)
        locations[kind]=loc["Id"] if loc else db.insert("catalog.Location",WarehouseId=wh,Code=code,Name=name,
                                      LocationType=kind,AllowsPicking=kind=="BIN",AllowsStorage=True,IsActive=True)
    for letter,city in [("A","Saltillo"),("B","Ramos Arizpe"),("C","Monterrey")]:
        customer=ensure(db,"catalog.Customer","Code","DEMO-CLI-"+letter,Name="Cliente "+letter+" · DEMO",IsActive=True)
        point=ensure(db,"catalog.LogisticsPoint","Code","DEMO-DEST-"+letter,Name=city+" · DEMO",PointType="DELIVERY_SITE",IsActive=True)
        if not db.one("SELECT Id FROM catalog.PointAddress WHERE PointId=?",point):
            db.insert("catalog.PointAddress",PointId=point,VersionNumber=1,AddressText="Dirección ficticia "+city,
                      City=city,CountryCode="MX",TimeZoneId="America/Monterrey",ValidFromUtc=now())
        if not db.one("SELECT Id FROM catalog.DeliverySite WHERE CustomerId=? AND Code=?",customer,"DEMO-DEST-"+letter):
            db.insert("catalog.DeliverySite",CustomerId=customer,Code="DEMO-DEST-"+letter,Name=city+" · DEMO",PointId=point,IsActive=True)
    pool=ensure(db,"planning.CapacityPool","Code","DEMO-PICK",WarehouseId=wh,StageCode="PICKING",
                CapacityBasis="BASE_QUANTITY",CapacityUnitId=unit,TimeZoneId="America/Monterrey",IsActive=True)
    for code,description in [("DEMO-MAT-01","Soporte de aluminio"),("DEMO-MAT-02","Carcasa de transmisión"),("DEMO-MAT-03","Ensamble lateral")]:
        mat=ensure(db,"catalog.Material","Code",code,Description=description,BaseUnitId=unit,RequiresLot=False,IsActive=True)
        if not db.one("SELECT Id FROM catalog.MaterialLocation WHERE MaterialId=? AND LocationId=?",mat,locations["BIN"]):
            db.insert("catalog.MaterialLocation",MaterialId=mat,LocationId=locations["BIN"],IsPreferred=True,IsActive=True)
        if not db.one("SELECT Id FROM planning.WorkStandardVersion WHERE PoolId=? AND MaterialId=?",pool,mat):
            db.insert("planning.WorkStandardVersion",PoolId=pool,MaterialId=mat,VersionNumber=1,CapacityPerBaseUnit=1,
                      ValidFromUtc=now(),Description="DEMO: una pieza ocupa una unidad de capacidad de picking.")
    trailer=ensure(db,"planning.Trailer","Code","DEMO-TR-01",Registration="DEMO001",RegistrationRegion="DEMO",IsActive=True)
    driver=ensure(db,"planning.Driver","Code","DEMO-CHOFER",DisplayName="Chofer de demostración",IsActive=True)
    ensure(db,"quality.IncidentType","Code","DEMO-INC",Name="Incidencia de demostración",DefaultSeverity="WARNING",IsActive=True)
    # Refresh only the original fictional labels; preserve custom names and all history.
    from backend.app.services.demo_catalog import destinations, record_distance
    products=[("DEMO-MAT-01","Soporte de aluminio","Coca-Cola 600 ml"),
              ("DEMO-MAT-02","Carcasa de transmisión","Sabritas Original 45 g"),
              ("DEMO-MAT-03","Ensamble lateral","Ruffles Queso 50 g")]
    for code,old,new in products:
        db.execute("UPDATE catalog.Material SET Description=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Code=? AND Description=?",new,code,old)
    stores=[("DEMO-DEST-A","Saltillo · DEMO","Oxxo Centro · ejemplo",5),
            ("DEMO-DEST-B","Ramos Arizpe · DEMO","Oxxo Universidad · ejemplo",12),
            ("DEMO-DEST-C","Monterrey · DEMO","Oxxo Las Torres · ejemplo",25)]
    for code,old,new,km in stores:
        db.execute("UPDATE catalog.DeliverySite SET Name=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Code=? AND Name=?",new,code,old)
        row=next((r for r in destinations(db) if r["codigo"]==code),None)
        if row and row["km"] is None:
            record_distance(db,row["address_id"],km)
    return dict(actor=actor,source=source,profile=pid,unit=unit,warehouse=wh,pool=pool,trailer=trailer,driver=driver,locations=locations)

def bootstrap():
    with transaction() as db:
        seed(db)
