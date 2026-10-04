"""Integration checks against a fresh, uniquely named SQL Server test database."""
from pathlib import Path
import os
import unittest
from uuid import uuid4
from backend.app.core.config import SqlSettings
from backend.app.init_database import initialize
from backend.app.repositories.connection import open_connection
from backend.app.repositories.demo import BusinessError
from backend.app.repositories.demo_queries import snapshot
from backend.app.services.demo_commands import execute
from backend.app.services.demo_seed import bootstrap

@unittest.skipUnless(os.environ.get("RUN_SQL_INTEGRATION")=="1","SQL integration opt-in required")
class DemoJourneyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.old=os.environ.get("SQL_DATABASE")
        cls.name="PPE_Journey_"+uuid4().hex[:10]+"_Test"
        os.environ["SQL_DATABASE"]=cls.name
        cls.settings=SqlSettings()
        initialize(cls.settings)
        bootstrap()

    @classmethod
    def tearDownClass(cls):
        with open_connection(cls.settings,server_only=True) as c:
            c.autocommit=True
            c.cursor().execute("ALTER DATABASE ["+cls.name+"] SET SINGLE_USER WITH ROLLBACK IMMEDIATE")
            c.cursor().execute("DROP DATABASE ["+cls.name+"]")
        if cls.old is None: os.environ.pop("SQL_DATABASE",None)
        else: os.environ["SQL_DATABASE"]=cls.old

    def test_full_csv_to_closed_trip_with_guards(self):
        sample=Path("samples/csv/demo_escritorio.csv").read_text(encoding="utf-8")
        def command(action,**payload): return execute(action,payload,uuid4())
        broken=sample.replace(",1000,PZA",",-5,PZA")
        result=command("import",content=broken,filename="invalid.csv")
        self.assertTrue(result["errors"])
        self.assertEqual(snapshot()["totals"]["cantidad"],0)
        key=uuid4()
        result=execute("import",dict(content=sample,filename="demo.csv"),key)
        self.assertEqual(result["errors"],[])
        self.assertEqual(execute("import",dict(content=sample,filename="demo.csv"),key),result)
        with self.assertRaises(BusinessError): execute("import",dict(content=sample+"\n",filename="demo.csv"),key)
        self.assertTrue(command("import",content=sample,filename="same.csv")["duplicate"])
        command("plan",start_date="2026-10-05",capacity=600)
        s=snapshot()
        self.assertTrue(all(r["id_pedido"]==r["pedido"] for r in s["lines"]))
        self.assertEqual([int(d["reservado"]) for d in s["days"]],[600,600,400])
        self.assertEqual(len(s["tasks"]),5)
        command("plan",start_date="2026-10-05",capacity=600)
        self.assertEqual(len(snapshot()["tasks"]),5)
        first=s["tasks"][0]
        with self.assertRaises(BusinessError): command("pack",id=first["id"],quantity=1)
        with self.assertRaises(BusinessError): command("pick",id=first["id"],quantity=1,location="WRONG",material=first["material"])
        with self.assertRaises(BusinessError): command("pick",id=first["id"],quantity=601,location=first["ubicacion"],material=first["material"])
        # Partial confirmations, then continue after reopening state from SQL.
        from concurrent.futures import ThreadPoolExecutor
        pick_key=uuid4()
        pick_payload=dict(id=first["id"],quantity=100,location=first["ubicacion"],material=first["material"])
        with ThreadPoolExecutor(max_workers=2) as pool:
            results=list(pool.map(lambda _:execute("pick",pick_payload,pick_key),range(2)))
        self.assertEqual(results[0],results[1])
        self.assertEqual(snapshot()["tasks"][0]["recogido"],100)
        for task in snapshot()["tasks"]:
            left=task["cantidad"]-task["recogido"]
            if left:
                command("pick",id=task["id"],quantity=int(left),location=task["ubicacion"],material=task["material"])
            command("pack",id=task["id"],quantity=int(task["cantidad"]))
        with self.assertRaises(BusinessError): command("pack",id=first["id"],quantity=1)
        for hu in snapshot()["units"]: command("stage",id=hu["id"])
        command("incident",id=snapshot()["lines"][0]["id"],reason="Prueba de observación, sin afectar cantidades")
        # Store distances can be changed, and the route uses km rather than code order.
        catalog=snapshot()["destinations"]
        site_b=next(r for r in catalog if r["codigo"]=="DEMO-DEST-B")
        for invalid in [0,-1,"nan","inf","1.0001","abc",100001,None]:
            with self.assertRaises(BusinessError):
                command("save_destination",id=site_b["id"],name=site_b["nombre"],km=invalid)
        command("save_destination",id=site_b["id"],name=site_b["nombre"],km=2.5)
        with self.assertRaises(BusinessError):
            command("create_trip",distance_ids=[-1])
        trip=command("create_trip")
        stops=snapshot()["stops"]
        self.assertEqual([float(r["km"]) for r in stops],[2.5,5,25])
        self.assertTrue(all(r["km_basis"]=="warehouse" for r in stops))
        command("save_destination",id=site_b["id"],name="Tienda Universidad actualizada",km=40)
        self.assertEqual(snapshot()["stops"],stops)
        bootstrap()
        self.assertEqual(next(r for r in snapshot()["destinations"] if r["id"]==site_b["id"])["km"],40)
        ship=trip["shipment_id"]
        units=snapshot()["units"]
        with self.assertRaises(BusinessError): command("close",id=ship,seal="DEMO")
        wrong=min(units,key=lambda u:u["parada"])
        with self.assertRaises(BusinessError): command("load",id=wrong["id"],code=wrong["codigo"])
        for hu in sorted(units,key=lambda u:-u["parada"]):
            command("load",id=hu["id"],code=hu["codigo"])
            with self.assertRaises(BusinessError): command("load",id=hu["id"],code=hu["codigo"])
        command("close",id=ship,seal="DEMO-001")
        end=snapshot()
        self.assertEqual(end["totals"]["embarcado"],1600)
        self.assertTrue(all(r["cantidad"]==r["embarcado"] for r in end["lines"]))
        self.assertEqual(end["shipments"][0]["estado"],"CLOSED")
        self.assertTrue(end["audit"])
        with self.assertRaises(BusinessError): command("close",id=ship,seal="DEMO-001")
        # A destination created by name can be used immediately by the friendly order form.
        result=command("save_destination",name="Tienda nueva",km=7.125)
        dest_id=result["destination_id"]
        with self.assertRaises(BusinessError):command("save_destination",name="Tienda nueva",km=4)
        with self.assertRaises(BusinessError):command("save_destination",id=-1,name="No existe",km=4)
        product=snapshot()["products"][0]
        self.assertEqual(product["nombre"],"Coca-Cola 600 ml")
        result=command("create_order",product_id=product["id"],destination_id=dest_id,quantity=24,due_date="2026-10-08")
        self.assertEqual(result["errors"],[])
        command("plan",start_date="2026-10-08",capacity=600)
        task=next(t for t in snapshot()["tasks"] if t["destino"]=="Tienda nueva")
        command("pick",id=task["id"],quantity=24,location=task["ubicacion"],material=task["material"])
        command("pack",id=task["id"],quantity=24)
        hu=next(u for u in snapshot()["units"] if u["estado"]=="PACKED")
        command("stage",id=hu["id"])
        next_trip=command("create_trip")
        stop=next(r for r in snapshot()["stops"] if r["shipment_id"]==next_trip["shipment_id"])
        self.assertEqual(float(stop["km"]),7.125)
        self.assertEqual(stop["destino"],"Tienda nueva")
        command("load",id=hu["id"],code=hu["codigo"])
        command("close",id=next_trip["shipment_id"],seal="DEMO-002")
        self.assertEqual(snapshot()["totals"]["embarcado"],1624)


    def test_z_txt_deliveries_import_and_duplicate(self):
        text=Path("samples/txt/entregas_domingo_a_miercoles.txt").read_text(encoding="utf-8")
        payload=dict(filename="entregas.txt",content=text)
        result=execute("import",payload,uuid4())
        self.assertEqual(result["errors"],[])
        lines=[r for r in snapshot()["lines"] if r["pedido"].startswith("DEMO-TXT-")]
        self.assertEqual(len(lines),4)
        self.assertEqual(sorted(str(r["fecha"]) for r in lines),
                         ["2026-10-04","2026-10-05","2026-10-06","2026-10-07"])
        self.assertEqual(sum(r["cantidad"] for r in lines),900)
        self.assertTrue(execute("import",payload,uuid4())["duplicate"])

if __name__=="__main__":
    unittest.main()
