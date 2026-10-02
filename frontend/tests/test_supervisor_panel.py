"""Supervisor reads are non-destructive and visibly stale on connection loss."""
import unittest
from datetime import date
from PySide6.QtWidgets import QApplication
from PySide6.QtTest import QTest
from backend.app.services.demo_supervisor import supervisor_view
from frontend.desktop.window import Window
from test_window import FakeApi


class SupervisorApi(FakeApi):
    fail=False
    def snapshot(self):
        if self.fail:raise RuntimeError("Sin conexión")
        state=super().snapshot()
        state["supervisor"]=supervisor_view(state,date(2026,10,5))
        return state


class SupervisorUiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        self.api=SupervisorApi();self.window=Window(self.api);self.window.show();self.wait()
    def wait(self):
        for _ in range(200):
            QTest.qWait(10)
            if self.window.state and not self.window.jobs:return
        self.fail("Read timed out")
    def tearDown(self):
        self.wait();self.window.close()
    def test_daily_summary_and_guidance_visible(self):
        panel=self.window.supervisor
        self.assertEqual(panel.values["programado"].text(),"100")
        self.assertEqual(panel.values["listo"].text(),"20")
        self.assertEqual(panel.queue.rowCount(),1)
        self.assertIn("Inventario sin verificar",panel.alerts.text())
        self.assertEqual(self.window.pages.currentIndex(),0)
    def test_poll_failure_preserves_values_and_marks_stale_without_dialog(self):
        self.api.fail=True;self.window.poll_supervisor();self.wait()
        self.assertIn("SIN ACTUALIZAR",self.window.supervisor.freshness.text())
        self.assertEqual(self.window.supervisor.values["listo"].text(),"20")
        self.assertIsNone(self.app.activeModalWidget())
        self.assertEqual(self.api.calls,[])
        self.api.fail=False;self.window.poll_supervisor();self.wait()
        self.assertNotIn("SIN ACTUALIZAR",self.window.supervisor.freshness.text())

    def test_operator_button_and_filters(self):
        seen=[]
        self.window.operator_requested.connect(lambda:seen.append(True))
        panel=self.window.supervisor
        panel.operator_button.click()
        self.assertEqual(seen,[True])
        panel.task_rows=[dict(id=1,pendiente=0,listo_empacar=0),
                         dict(id=2,pendiente=10,listo_empacar=0),
                         dict(id=3,pendiente=10,listo_empacar=5)]
        panel.filter_tasks()
        self.assertEqual(panel.queue.rowCount(),2)
        panel.filter.setCurrentIndex(1)
        self.assertEqual(panel.queue.rowCount(),1)
        self.assertEqual(panel.queue.selected()["id"],3)
        panel.filter.setCurrentIndex(2)
        self.assertEqual(panel.queue.rowCount(),3)
