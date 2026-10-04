import unittest
from PySide6.QtWidgets import QApplication,QWidget,QVBoxLayout
from PySide6.QtCore import QDate
from frontend.desktop.widgets import DataTable

class DateFilterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        self.host=QWidget();layout=QVBoxLayout(self.host)
        self.table=DataTable([("id","ID"),("fecha","Fecha")]);layout.addWidget(self.table)
        self.controls=self.table.add_dates(layout,"fecha","Fecha real",True)
        self.rows=[dict(id=1,fecha="2026-10-05T01:00:00"),dict(id=2,fecha="2026-10-05T15:00:00"),dict(id=3,fecha=None)]
        self.table.populate(self.rows)
    def tearDown(self):self.host.close()
    def ids(self):return [self.table.item(i,0).data(256)["id"] for i in range(self.table.rowCount())]
    def test_both_orders_and_empty_dates(self):
        self.assertEqual(self.ids(),[2,1,3])
        self.controls.order.setCurrentIndex(1)
        self.assertEqual(self.ids(),[1,2,3])
    def test_exact_local_date_survives_refresh_and_clear(self):
        self.controls.date.setDate(QDate(2026,10,4));self.controls.exact.setChecked(True)
        self.assertEqual(self.ids(),[1])
        self.table.populate(self.rows)
        self.assertEqual(self.ids(),[1])
        self.assertIn("2026-10-04",self.table.item(0,1).text())
        self.controls.date.setDate(QDate(2026,10,8))
        self.assertEqual(self.ids(),[])
        self.controls.exact.setChecked(False)
        self.assertEqual(len(self.ids()),3)
