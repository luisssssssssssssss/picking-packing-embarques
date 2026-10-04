"""Presentation rehearsal in an isolated SQL test database; never uses the presentation DB."""
import os
import unittest
from datetime import date
from pathlib import Path
from uuid import uuid4
from backend.tests import test_demo_operator as existing
from backend.app.services.demo_commands import execute
from backend.app.services.demo_operator_calendar import calendar_view
from backend.app.repositories.demo_queries import snapshot

@unittest.skipUnless(os.environ.get("RUN_SQL_INTEGRATION")=="1","SQL opt-in")
class PresentationSqlTests(unittest.TestCase):
    setUpClass=classmethod(existing.OperatorSqlTests.setUpClass.__func__)
    tearDownClass=classmethod(existing.OperatorSqlTests.tearDownClass.__func__)
    def test_sunday_three_warehouses_complete_journey(self):
        def cmd(action,**payload):return execute(action,payload,uuid4())
        content=Path("samples/txt/presentacion_domingo_20261004.txt").read_text(encoding="utf-8")
        self.assertTrue(cmd("import",filename="duplicate-id.txt",content=content.replace("PED-002","PED-001"))["errors"])
        self.assertTrue(cmd("import",filename="empty-id.txt",content=content.replace("PED-001|","|"))["errors"])
        self.assertTrue(cmd("import",filename="inconsistent.txt",content=content.replace("DEMO-PRESENTACION-20261004-02|1","DEMO-PRESENTACION-20261004-01|2"))["errors"])
        self.assertFalse(cmd("import",filename="domingo.txt",content=content)["errors"])
        expected={f"PED-{i:03}" for i in range(1,7)}
        self.assertEqual({r["id_pedido"] for r in snapshot()["lines"]},expected)
        self.assertTrue(cmd("import",filename="existing-id.txt",content=content.replace("DEMO-PRESENTACION-","DEMO-ANOTHER-"))["errors"])
        cmd("plan",start_date="2026-10-04",capacity=600)
        state=snapshot()
        self.assertEqual({t["id_pedido"] for t in state["tasks"]},expected)
        self.assertEqual(len(state["tasks"]),6)
        self.assertEqual({str(t["fecha"]) for t in state["tasks"]},{"2026-10-04"})
        self.assertEqual(len({t["WarehouseId"] for t in state["tasks"]}),3)
        self.assertEqual(sum(t["cantidad"] for t in state["tasks"]),240)
        for _ in range(18):
            task=calendar_view(snapshot(),today=date(2026,10,4))["task"]
            self.assertIn(task["action"],("pick","pack","stage"))
            self.assertIn(task["order"],expected)
            self.assertEqual(cmd(task["action"],**task["payload"])["id_pedido"],task["order"])
        state=snapshot()
        self.assertEqual({u["id_pedido"] for u in state["units"]},expected)
        self.assertEqual(len(state["units"]),6)
        groups={}
        for unit in state["units"]:groups.setdefault(unit["WarehouseId"],[]).append(unit["id"])
        for ids in groups.values():
            trip=cmd("create_trip",unit_ids=ids)
            for _ in ids:
                task=calendar_view(snapshot(),today=date(2026,10,4))["task"]
                self.assertEqual(task["action"],"load")
                cmd(task["action"],**task["payload"])
            cmd("close",id=trip["shipment_id"],seal="ENSAYO")
        state=snapshot()
        self.assertEqual(state["totals"]["embarcado"],240)
        import json
        from backend.app.repositories.demo import transaction
        with transaction(False) as db:
            manifests=db.rows("SELECT ManifestJson FROM shipping.ShipmentClosure")
        self.assertEqual({u["id_pedido"] for m in manifests for u in json.loads(m["ManifestJson"])["units"]},expected)
        self.assertIsNone(calendar_view(state,today=date(2026,10,4))["task"])

@unittest.skipUnless(os.environ.get("RUN_SQL_INTEGRATION")=="1","SQL opt-in")
class OrderIdentitySqlTests(unittest.TestCase):
    setUpClass=classmethod(existing.OperatorSqlTests.setUpClass.__func__)
    tearDownClass=classmethod(existing.OperatorSqlTests.tearDownClass.__func__)
    def test_same_product_quantity_distinct_orders_and_multiline_id(self):
        def cmd(action,**payload):return execute(action,payload,uuid4())
        lines=Path("samples/txt/presentacion_domingo_20261004.txt").read_text(encoding="utf-8").splitlines()
        first=lines[1].replace("PED-001","00001").replace("|48|","|60|")
        second=first.replace("00001|","00002|",1).replace("20261004-01|1","20261004-02|1")
        extra=first.replace("20261004-01|1","20261004-01|2").replace("|60|","|5|")
        result=cmd("import",filename="same-products.txt",content="\n".join([lines[0],first,second,extra]))
        self.assertFalse(result["errors"])
        state=snapshot()
        self.assertEqual([(r["id_pedido"],r["cantidad"]) for r in state["lines"]],[("00001",60),("00001",5),("00002",60)])
        cmd("plan",start_date="2026-10-04",capacity=600)
        task=next(t for t in snapshot()["tasks"] if t["id_pedido"]=="00001" and t["cantidad"]==60)
        cmd("pick",id=task["id"],quantity=30,material=task["material"],location=task["ubicacion"])
        unit=cmd("pack",id=task["id"],quantity=30)
        cmd("stage",id=unit["hu_id"])
        state=snapshot()
        self.assertEqual(state["units"][0]["id_pedido"],"00001")
        self.assertEqual(next(t for t in state["tasks"] if t["id_pedido"]=="00002")["recogido"],0)
        second=next(t for t in state["tasks"] if t["id_pedido"]=="00002")
        cmd("pick",id=second["id"],quantity=60,material=second["material"],location=second["ubicacion"])
        other=cmd("pack",id=second["id"],quantity=60)
        cmd("stage",id=other["hu_id"])
        trip=cmd("create_trip",unit_ids=[unit["hu_id"]])
        state=snapshot()
        chosen=next(u for u in state["units"] if u["id"]==unit["hu_id"])
        waiting=next(u for u in state["units"] if u["id"]==other["hu_id"])
        self.assertEqual(chosen["shipment_id"],trip["shipment_id"])
        self.assertIsNone(waiting["shipment_id"])
        self.assertEqual(waiting["estado"],"STAGED")


@unittest.skipUnless(os.environ.get("RUN_SQL_INTEGRATION")=="1","SQL opt-in")
class SecondExerciseSqlTests(unittest.TestCase):
    setUpClass=classmethod(existing.OperatorSqlTests.setUpClass.__func__)
    tearDownClass=classmethod(existing.OperatorSqlTests.tearDownClass.__func__)
    def test_second_exercise_has_distinct_identifiers(self):
        content=Path("samples/txt/ejercicio_2_domingo.txt").read_text(encoding="utf-8")
        result=execute("import",dict(filename="ejercicio_2.txt",content=content),uuid4())
        self.assertFalse(result["errors"])
        execute("plan",dict(start_date="2026-10-04",capacity=600),uuid4())
        s=snapshot()
        self.assertEqual(s["totals"]["cantidad"],360)
        self.assertEqual(len(s["tasks"]),8)
        self.assertEqual(len({r["id_pedido"] for r in s["lines"]}),8)
        coke=[r for r in s["lines"] if r["material"]=="DEMO-MAT-01"]
        self.assertEqual([r["cantidad"] for r in coke],[60,60,60])
        self.assertEqual({str(t["fecha"]) for t in s["tasks"]},{"2026-10-04"})
