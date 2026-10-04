"""Explicit fictional names and independent demo warehouse catalogs."""
from backend.app.repositories.demo import now, BusinessError

def warehouse_context(db,ctx,warehouse_id):
    locations=db.rows("SELECT Id,LocationType FROM catalog.Location WHERE WarehouseId=? AND IsActive=1",warehouse_id)
    pool=db.scalar("SELECT Id FROM planning.CapacityPool WHERE WarehouseId=? AND Code LIKE 'DEMO-PICK%'",warehouse_id)
    return dict(ctx,warehouse=warehouse_id,pool=pool,locations={r["LocationType"]:r["Id"] for r in locations})

def familiar_catalog(db,actor,unit,warehouse):
    from backend.app.services.demo_seed import ensure
    from backend.app.services.demo_catalog import record_distance
    db.execute("UPDATE catalog.Warehouse SET Name=N'Almacén cuarto de Víctor' WHERE Id=? AND Name=N'Monterrey · DEMO'",warehouse)
    point=ensure(db,"catalog.LogisticsPoint","Code","DEMO-HUICHO",Name="Almacén cuarto de Huicho",PointType="WAREHOUSE",IsActive=True)
    ensure(db,"catalog.PointAddress","PointId",point,VersionNumber=1,AddressText="Cuarto de Huicho · dirección ficticia",City="Monterrey",CountryCode="MX",TimeZoneId="America/Monterrey",ValidFromUtc=now())
    wh=ensure(db,"catalog.Warehouse","Code","DEMO-HUICHO",Name="Almacén cuarto de Huicho",PointId=point,IsActive=True)
    locs={}
    for code,name,kind in [("BIN","Rack de surtido","BIN"),("PACK","Mesa de empaque","PACKING"),("STG","Área de salida","STAGING"),("DOCK","Andén","DOCK")]:
        locs[kind]=ensure(db,"catalog.Location","Code","DEMO-H-"+code,WarehouseId=wh,Name=name,LocationType=kind,AllowsPicking=kind=="BIN",AllowsStorage=True,IsActive=True)
    pool=ensure(db,"planning.CapacityPool","Code","DEMO-PICK-HUICHO",WarehouseId=wh,StageCode="PICKING",CapacityBasis="BASE_QUANTITY",CapacityUnitId=unit,TimeZoneId="America/Monterrey",IsActive=True)
    for code,name in [("DEMO-MAT-04","Doritos Nacho 58 g"),("DEMO-MAT-05","Agua Ciel 1 L"),("DEMO-MAT-06","Gansito 50 g")]:
        mat=ensure(db,"catalog.Material","Code",code,Description=name,BaseUnitId=unit,RequiresLot=False,IsActive=True)
        if not db.one("SELECT Id FROM catalog.MaterialLocation WHERE MaterialId=? AND LocationId=?",mat,locs["BIN"]):
            db.insert("catalog.MaterialLocation",MaterialId=mat,LocationId=locs["BIN"],IsPreferred=True,IsActive=True)
        if not db.one("SELECT Id FROM planning.WorkStandardVersion WHERE PoolId=? AND MaterialId=?",pool,mat):
            db.insert("planning.WorkStandardVersion",PoolId=pool,MaterialId=mat,VersionNumber=1,CapacityPerBaseUnit=1,ValidFromUtc=now(),Description="Una pieza por unidad de capacidad")
    point=ensure(db,"catalog.LogisticsPoint","Code","DEMO-VELOCO",Name="Almacén cuarto de Veloco",PointType="WAREHOUSE",IsActive=True)
    ensure(db,"catalog.PointAddress","PointId",point,VersionNumber=1,AddressText="Cuarto de Veloco · dirección ficticia",City="Monterrey",CountryCode="MX",TimeZoneId="America/Monterrey",ValidFromUtc=now())
    veloco=ensure(db,"catalog.Warehouse","Code","DEMO-VELOCO",Name="Almacén cuarto de Veloco",PointId=point,IsActive=True)
    locs={}
    for code,name,kind in [("BIN","Rack de surtido","BIN"),("PACK","Mesa de empaque","PACKING"),("STG","Área de salida","STAGING"),("DOCK","Andén","DOCK")]:
        locs[kind]=ensure(db,"catalog.Location","Code","DEMO-V-"+code,WarehouseId=veloco,Name=name,LocationType=kind,AllowsPicking=kind=="BIN",AllowsStorage=True,IsActive=True)
    pool=ensure(db,"planning.CapacityPool","Code","DEMO-PICK-VELOCO",WarehouseId=veloco,StageCode="PICKING",CapacityBasis="BASE_QUANTITY",CapacityUnitId=unit,TimeZoneId="America/Monterrey",IsActive=True)
    for code,name in [("DEMO-MAT-07","Pepsi 600 ml"),("DEMO-MAT-08","Cheetos Torciditos 52 g")]:
        mat=ensure(db,"catalog.Material","Code",code,Description=name,BaseUnitId=unit,RequiresLot=False,IsActive=True)
        if not db.one("SELECT Id FROM catalog.MaterialLocation WHERE MaterialId=? AND LocationId=?",mat,locs["BIN"]):
            db.insert("catalog.MaterialLocation",MaterialId=mat,LocationId=locs["BIN"],IsPreferred=True,IsActive=True)
        if not db.one("SELECT Id FROM planning.WorkStandardVersion WHERE PoolId=? AND MaterialId=?",pool,mat):
            db.insert("planning.WorkStandardVersion",PoolId=pool,MaterialId=mat,VersionNumber=1,CapacityPerBaseUnit=1,ValidFromUtc=now(),Description="Una pieza por unidad de capacidad")
    for code,name,km in [("RALDE","La Ralde",7),("OXXO","Oxxo",1),("SALMA","Salma",20)]:
        customer=ensure(db,"catalog.Customer","Code","DEMO-CLI-"+code,Name=name,IsActive=True)
        point=ensure(db,"catalog.LogisticsPoint","Code","DEMO-DEST-"+code,Name=name,PointType="DELIVERY_SITE",IsActive=True)
        address=ensure(db,"catalog.PointAddress","PointId",point,VersionNumber=1,AddressText="Destino ficticio: "+name,City="Monterrey",CountryCode="MX",TimeZoneId="America/Monterrey",ValidFromUtc=now())
        ensure(db,"catalog.DeliverySite","Code","DEMO-DEST-"+code,CustomerId=customer,Name=name,PointId=point,IsActive=True)
        for origin in (warehouse,wh,veloco):
            origin_address=db.scalar("SELECT pa.Id FROM catalog.PointAddress pa JOIN catalog.Warehouse w ON w.PointId=pa.PointId WHERE w.Id=? AND pa.VersionNumber=1",origin)
            if not db.one("SELECT Id FROM planning.DistanceReference WHERE OriginAddressId=? AND DestinationAddressId=? AND SourceDescription LIKE 'DEMO: kilómetros capturados%'",origin_address,address):
                record_distance(db,address,km,origin)
