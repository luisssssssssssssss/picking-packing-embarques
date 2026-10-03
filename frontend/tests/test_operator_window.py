"""Operator UI: direct confirmations, partial quantities and retry identity."""
import unittest
from PySide6.QtWidgets import QApplication,QTableWidget
from PySide6.QtTest import QTest
from PySide6.QtCore import Qt
from frontend.desktop.operator_window import OperatorWindow
from frontend.desktop.client import ApiError


class OperatorApi:
    def __init__(self):
        self.posts=[];self.keys=set();self.phase=0;self.fail_once=False;self.conflict=False
    def request(self,method,path,**kwargs):
        if method=="POST":
            data=kwargs["json"];self.posts.append(data)
            if self.conflict:raise ApiError("La disponibilidad cambió.",409)
            if data["key"] not in self.keys:self.keys.add(data["key"]);self.phase+=1
            if self.fail_once:self.fail_once=False;raise RuntimeError("Conexión interrumpida")
            return dict(message="Guardado")
        action="pick" if self.phase==0 else "pack"
        task=dict(action=action,payload=dict(id=1,quantity=48),quantity=48,product="Coca-Cola 600 ml",
            source="Almacén Norte · Rack 01",destination="Almacén Norte · Mesa de empaque",
            store="Tienda Centro",allocation_id=10,line_id=100,step=1 if action=="pick" else 2,
            order="DEMO-P1",scheduled_date="2026-10-01",hu=None,can_adjust=True)
        if action=="pick":task["payload"].update(location="R01",material="DEMO-01")
        return dict(task=task,pending=1,message="",demo=True)


class OperatorDesktopTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        self.api=OperatorApi();self.window=OperatorWindow(self.api);self.window.show();self.wait()
    def wait(self):
        for _ in range(200):
            QTest.qWait(10)
            if self.window.state and not self.window.jobs:return
        self.fail("Timeout")
    def tearDown(self):
        self.window.pending=None;self.window.close()

    def test_one_instruction_without_tables_and_direct_confirmation(self):
        self.assertEqual(self.window.findChildren(QTableWidget),[])
        self.assertEqual(self.window.product.text(),"Coca-Cola 600 ml")
        self.assertIn("48",self.window.confirm.text())
        QTest.mouseClick(self.window.confirm,Qt.MouseButton.LeftButton)
        self.assertFalse(self.window.confirm.isEnabled())
        self.window.confirm_task()  # A rapid second activation cannot send another command.
        self.wait()
        self.assertEqual(len(self.api.posts),1)
        self.assertEqual(self.window.task["action"],"pack")
        self.assertIsNone(self.app.activeModalWidget())

    def test_partial_quantity_is_sent(self):
        self.window.toggle_quantity();self.window.quantity.setValue(20)
        self.window.confirm_task();self.wait()
        self.assertEqual(self.api.posts[0]["payload"]["quantity"],20)

    def test_network_retry_reuses_identity(self):
        self.api.fail_once=True
        self.window.confirm_task();self.wait()
        self.assertEqual(self.window.confirm.text(),"Reintentar confirmación")
        self.assertFalse(self.window.refresh_button.isEnabled())
        self.window.confirm_task();self.wait()
        self.assertEqual(self.api.posts[0],self.api.posts[1])
        self.assertEqual(self.api.phase,1)
        self.assertIsNone(self.window.pending)

    def test_conflict_requires_fresh_task(self):
        self.api.conflict=True
        self.window.confirm_task();self.wait()
        self.assertIsNone(self.window.pending);self.assertIsNone(self.window.task)
        self.assertEqual(self.window.confirm.text(),"Actualizar tareas")

    def test_compact_layout_keeps_confirmation_visible(self):
        self.window.resize(390,780);QTest.qWait(30)
        self.assertLessEqual(self.window.width(),390)
        self.assertTrue(self.window.confirm.isVisible())
        self.assertGreaterEqual(self.window.confirm.height(),60)
        self.assertGreaterEqual(self.window.confirm.geometry().top(),0)
        self.assertLessEqual(self.window.confirm.geometry().bottom(),self.window.centralWidget().height())
