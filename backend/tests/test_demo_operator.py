"""Operational instruction selection and full SQL-backed operator journey."""
import os
import unittest
from uuid import uuid4
from backend.app.services.demo_operator import operator_view
from backend.app.services.demo_commands import execute
from backend.app.services.demo_seed import bootstrap
from backend.app.repositories.demo_queries import snapshot
from backend.app.core.config import SqlSettings
from backend.app.init_database import initialize
from backend.app.repositories.connection import open_connection


def sample_state():
    task=dict(id=1,AllocationId=10,line_id=100,estado="OPEN",fecha="2026-10-01",
        descripcion="Coca-Cola 600 ml",cantidad=48,recogido=0,empacado=0,
        ubicacion="R01",ubicacion_nombre="Rack 01",almacen="Almacén Norte",
        destino="Tienda Centro",material="DEMO-01",pedido="DEMO-P1")
    return dict(tasks=[task],units=[],shipments=[],
        locations=[dict(kind=kind,nombre=name,codigo=kind,almacen="Almacén Norte")
                   for kind,name in [("PACKING","Mesa de empaque"),("STAGING","Salida")]],
        totals=dict(cantidad=48,planeado=48))


class OperatorRulesTests(unittest.TestCase):
    def test_unplanned_orders_do_not_become_operator_tasks(self):
        state=sample_state();state["tasks"]=[];state["totals"]["planeado"]=0
        view=operator_view(state)
        self.assertIsNone(view["task"]);self.assertIn("supervisor",view["message"])

    def test_partial_pick_goes_to_packing_in_same_allocation(self):
        state=sample_state();state["tasks"][0]["recogido"]=20
        view=operator_view(state,10)
        self.assertEqual(view["task"]["action"],"pack")
        self.assertEqual(view["task"]["quantity"],20)
        self.assertIn("Almacén Norte",view["task"]["destination"])
        self.assertEqual(view["task"]["payload"],dict(id=1,quantity=20))

    def test_reverse_load_order_and_completed_units(self):
        state=sample_state();state["tasks"]=[]
        state["shipments"]=[dict(id=1,estado="OPEN",anden="Andén 1",trailer="TR-1")]
        template=dict(id=2,AllocationId=10,line_id=100,descripcion="Coca-Cola",cantidad=48,
            estado="STAGED",shipment_id=1,destino="Tienda",pedido="DEMO-P1",codigo="HU-2",
            almacen="Norte",ubicacion_nombre="Salida",ubicacion="STG")
        state["units"]=[dict(template,parada=1),dict(template,id=3,parada=3,codigo="HU-3"),
                        dict(template,id=4,parada=4,estado="LOADED")]
        task=operator_view(state)["task"]
        self.assertEqual(task["payload"],dict(id=3,code="HU-3"))
        self.assertIn("TR-1",task["destination"])

    def test_preferred_product_stays_selected(self):
        state=sample_state()
        state["tasks"].append(dict(state["tasks"][0],id=2,AllocationId=20,recogido=24))
        task=operator_view(state,20)["task"]
        self.assertEqual(task["allocation_id"],20);self.assertEqual(task["action"],"pack")

    def test_missing_layout_is_reported(self):
        state=sample_state();state["locations"]=[]
        view=operator_view(state)
        self.assertIsNone(view["task"]);self.assertIn("configurar",view["message"])


@unittest.skipUnless(os.environ.get("RUN_SQL_INTEGRATION")=="1","SQL integration opt-in required")
class OperatorSqlTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.old=os.environ.get("SQL_DATABASE")
        cls.name="PPE_Operator_"+uuid4().hex[:10]+"_Test"
        os.environ["SQL_DATABASE"]=cls.name;cls.settings=SqlSettings()
        initialize(cls.settings);bootstrap()

    @classmethod
    def tearDownClass(cls):
        with open_connection(cls.settings,server_only=True) as c:
            c.autocommit=True
            c.cursor().execute("ALTER DATABASE ["+cls.name+"] SET SINGLE_USER WITH ROLLBACK IMMEDIATE")
            c.cursor().execute("DROP DATABASE ["+cls.name+"]")
        if cls.old is None:os.environ.pop("SQL_DATABASE",None)
        else:os.environ["SQL_DATABASE"]=cls.old

    def test_single_instruction_journey_with_partial_quantities(self):
        def command(action,**payload):return execute(action,payload,uuid4())
        initial=snapshot()
        command("create_order",product_id=initial["products"][0]["id"],
                destination_id=initial["destinations"][0]["id"],quantity=48,due_date="2026-10-02")
        self.assertIsNone(operator_view(snapshot())["task"])
        command("plan",capacity=600,start_date="2026-10-03")
        self.assertEqual(str(snapshot()["tasks"][0]["fecha"]),"2026-10-03")
        task=operator_view(snapshot())["task"]
        self.assertEqual(task["action"],"pick");self.assertEqual(task["quantity"],48)
        self.assertIn("Rack",task["source"])
        preferred=task["allocation_id"]
        for qty in (20,28):
            current=operator_view(snapshot(),preferred)["task"]
            self.assertEqual(current["action"],"pick")
            payload=dict(current["payload"],quantity=qty)
            command("pick",**payload)
            current=operator_view(snapshot(),preferred)["task"]
            self.assertEqual(current["action"],"pack");self.assertEqual(current["quantity"],qty)
            command("pack",**current["payload"])
            current=operator_view(snapshot(),preferred)["task"]
            self.assertEqual(current["action"],"stage");self.assertEqual(current["quantity"],qty)
            self.assertIn("Mesa de empaque",current["source"])
            command("stage",**current["payload"])
        self.assertIsNone(operator_view(snapshot(),preferred)["task"])
        trip=command("create_trip")
        for _ in range(2):
            current=operator_view(snapshot(),preferred)["task"]
            self.assertEqual(current["action"],"load")
            command("load",**current["payload"])
        self.assertIn("cerrar",operator_view(snapshot())["message"])
        command("close",id=trip["shipment_id"],seal="DEMO-OPERATOR")
        self.assertEqual(snapshot()["totals"]["embarcado"],48)
        self.assertIsNone(operator_view(snapshot())["task"])
