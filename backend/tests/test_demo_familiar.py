import os
import unittest
from datetime import date
from pathlib import Path
from uuid import uuid4
from unittest.mock import patch
from backend.tests import test_demo_operator as existing
from backend.app.services.demo_operator_calendar import calendar_view
from backend.app.repositories.demo import BusinessError
from backend.app.repositories.demo_queries import snapshot
from backend.app.services.demo_commands import execute

class CalendarViewTests(unittest.TestCase):
    def test_future_is_read_only_and_past_is_rejected(self):
        state=existing.sample_state()
        state["tasks"][0]["fecha"]="2026-10-05"
        preview=calendar_view(state,date(2026,10,5),today=date(2026,10,3))
        self.assertTrue(preview["read_only"])
        self.assertIsNone(preview["task"])
        self.assertEqual(preview["preview"][0]["quantity"],48)
        current=calendar_view(state,today=date(2026,10,3))
        self.assertIsNone(current["task"])
        with self.assertRaises(BusinessError):
            calendar_view(state,date(2026,10,2),today=date(2026,10,3))

@unittest.skipUnless(os.environ.get("RUN_SQL_INTEGRATION")=="1","SQL opt-in")
class FamiliarSqlTests(unittest.TestCase):
    setUpClass=classmethod(existing.OperatorSqlTests.setUpClass.__func__)
    tearDownClass=classmethod(existing.OperatorSqlTests.tearDownClass.__func__)
    def test_readable_txt_independent_warehouses_and_future_guard(self):
        def cmd(action,**payload):return execute(action,payload,uuid4())
        content=Path("samples/txt/pedidos_legibles.txt").read_text(encoding="utf-8")
        bad=cmd("import",filename="bad.txt",content=content.replace("Coca-Cola 600 ml","Pepsi"))
        self.assertTrue(bad["errors"]);self.assertEqual(snapshot()["totals"]["cantidad"],0)
        self.assertFalse(cmd("import",filename="legible.txt",content=content)["errors"])
        self.assertTrue(cmd("import",filename="legible.txt",content=content)["duplicate"])
        cmd("plan",start_date="2026-10-03",capacity=600)
        state=snapshot()
        self.assertEqual(len({t["WarehouseId"] for t in state["tasks"]}),2)
        for task in state["tasks"]:
            cmd("pick",id=task["id"],quantity=task["cantidad"],material=task["material"],location=task["ubicacion"])
            unit=cmd("pack",id=task["id"],quantity=task["cantidad"])
            cmd("stage",id=unit["hu_id"])
        state=snapshot()
        bywarehouse={}
        for unit in state["units"]:
            bywarehouse.setdefault(unit["WarehouseId"],[]).append(unit["id"])
            self.assertIn(unit["almacen"],("Almacén cuarto de Víctor","Almacén cuarto de Huicho"))
        with self.assertRaises(BusinessError):cmd("create_trip")
        for ids in bywarehouse.values():
            trip=cmd("create_trip",unit_ids=ids)
            for unit in sorted([u for u in snapshot()["units"] if u["id"] in ids],key=lambda u:-u["parada"]):
                cmd("load",id=unit["id"],code=unit["codigo"])
            cmd("close",id=trip["shipment_id"],seal="TEST")
        self.assertEqual(snapshot()["totals"]["embarcado"],900)
        state=snapshot()
        cmd("create_order",product_id=state["products"][0]["id"],destination_id=state["destinations"][0]["id"],quantity=10,due_date="2026-10-05")
        cmd("plan",start_date="2026-10-05",capacity=600)
        future=next(t for t in snapshot()["tasks"] if str(t["fecha"])=="2026-10-05")
        with patch("backend.app.services.demo_operator_calendar.today_local",return_value=date(2026,10,3)):
            with self.assertRaises(BusinessError):
                execute("pick",dict(id=future["id"],quantity=10,material=future["material"],location=future["ubicacion"],operator_date="2026-10-03"),uuid4(),operator=True)
        self.assertEqual(next(t for t in snapshot()["tasks"] if t["id"]==future["id"])["recogido"],0)
