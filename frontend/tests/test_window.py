"""Interaction tests for guided defaults and correct next actions."""
import unittest
from PySide6.QtWidgets import QApplication,QDialog,QSpinBox,QComboBox,QDoubleSpinBox,QLineEdit
from PySide6.QtCore import QTimer
from PySide6.QtTest import QTest
from frontend.desktop.window import Window

class FakeApi:
    def __init__(self): self.calls=[]
    def snapshot(self):
        return dict(totals=dict(cantidad=100,planeado=100,recogido=20,empacado=0,embarcado=0),
          lines=[dict(id=1,pedido="DEMO-01",linea="10",cliente="DEMO",material="DEMO-MAT-01",descripcion="Coca-Cola 600 ml",destino="Tienda Centro",cantidad=100,embarcado=0,fecha="2026-10-05")],
          tasks=[dict(id=9,pedido="DEMO-01",material="DEMO-MAT-01",descripcion="Coca-Cola 600 ml",ubicacion="DEMO-R01",fecha="2026-10-05",cantidad=100,recogido=20,empacado=0,destino="Tienda Centro")],
          products=[dict(id=1,codigo="DEMO-MAT-01",nombre="Coca-Cola 600 ml")],
          destinations=[dict(id=2,nombre="Tienda Centro",km=5,distance_id=3)],
          days=[],units=[],shipments=[],imports=[],errors=[],audit=[],incidents=[],stops=[])
    def sample(self): return dict(filename="demo.csv",content="CSV de prueba")
    def command(self,action,**payload):
        self.calls.append((action,payload));return dict(message="Guardado")

class DesktopTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        self.api=FakeApi();self.window=Window(self.api);self.window.show();self.wait()
    def tearDown(self):self.wait();self.window.close()
    def wait(self):
        for _ in range(200):
            QTest.qWait(10)
            if self.window.state and not self.window.jobs:return
        self.fail("Desktop task timed out")
    def test_navigation_and_pending_action(self):
        self.assertEqual(self.window.nav.item(0).text(),"Hoy")
        self.assertEqual(self.window.nav.count(),5)
        for index in range(5):
            self.window.nav.setCurrentRow(index)
            self.assertEqual(self.window.pages.currentIndex(),index)
        self.assertEqual(self.window.next_kind,"pack")
        self.assertEqual(self.window.worklist.selected()["id"],9)
    def test_pick_defaults_without_typing_codes(self):
        seen={}
        def form(title,description,fields):
            seen["description"]=description;seen["fields"]=fields
            return dict(quantity=10)
        self.window.form=form;self.window.pick();self.wait()
        self.assertIn("Coca-Cola",seen["description"])
        self.assertEqual(seen["fields"],[("quantity","Piezas que recogiste",80)])
        self.assertEqual(self.api.calls,[("pick",dict(id=9,location="DEMO-R01",material="DEMO-MAT-01",quantity=10))])
    def test_new_order_defaults(self):
        seen={}
        def accept():
            dialog=self.app.activeModalWidget()
            seen["quantity"]=dialog.findChild(QSpinBox).value()
            seen["choices"]=[w.currentText() for w in dialog.findChildren(QComboBox)]
            dialog.accept()
        QTimer.singleShot(20,accept);self.window.new_order();self.wait()
        self.assertEqual(seen,dict(quantity=24,choices=["Coca-Cola 600 ml","Tienda Centro"]))
        action,payload=self.api.calls[0];self.assertEqual(action,"create_order")
        self.assertEqual(payload["destination_id"],2);self.assertEqual(payload["quantity"],24)
    def test_destination_form_saved_name_and_km(self):
        def accept():
            dialog=self.app.activeModalWidget()
            dialog.findChild(QLineEdit).setText("Tienda nueva")
            dialog.findChild(QDoubleSpinBox).setValue(7.125);dialog.accept()
        QTimer.singleShot(20,accept);self.window.destination_form();self.wait()
        self.assertEqual(self.api.calls,[("save_destination",dict(name="Tienda nueva",km=7.125))])
    def test_load_automatically_chooses_last_delivery(self):
        state=self.api.snapshot()
        state["shipments"]=[dict(id=30,viaje="DEMO-VIA-1",estado="OPEN",unidades=2,cargadas=0)]
        state["units"]=[dict(id=i,codigo=f"HU-{i}",shipment_id=30,DeliverySiteId=i,descripcion="Coca-Cola",destino=f"Tienda {i}",cantidad=24,parada=i,estado="STAGED") for i in (1,2)]
        self.window.render(state);self.window.form=lambda *args:{}
        self.window.load();self.wait()
        self.assertEqual(self.api.calls,[("load",dict(id=2,code="HU-2"))])
    def test_import_sample_one_action(self):
        self.window.import_sample();self.wait()
        self.assertEqual(self.api.calls,[("import",dict(filename="demo.csv",content="CSV de prueba"))])

if __name__=="__main__":unittest.main()
