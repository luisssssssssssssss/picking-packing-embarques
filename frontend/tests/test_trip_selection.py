import unittest
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import Qt
from frontend.desktop.trip_selection import TripSelectionDialog

class TripSelectionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        def unit(id,wh,site,state="STAGED",shipment=None):
            return dict(id=id,WarehouseId=wh,almacen=f"Almacén {wh}",DeliverySiteId=site,estado=state,shipment_id=shipment,id_pedido=f"PED-{id}",descripcion="Coca-Cola",cantidad=48,destino=f"Destino {site}",codigo=f"HU-{id}")
        sites=[dict(id=1,nombre="Cerca",km=1,distance_id=10),dict(id=2,nombre="Lejos",km=20,distance_id=20)]
        self.dialog=TripSelectionDialog(dict(units=[unit(1,1,1),unit(2,1,2),unit(3,2,1),unit(4,1,1,"PACKED"),unit(5,1,1,shipment=7)],destinations_by_warehouse={"1":sites,"2":sites}))
    def tearDown(self):self.dialog.close()
    def test_explicit_subset_excludes_other_available_units(self):
        d=self.dialog
        self.assertEqual(d.table.rowCount(),2);self.assertFalse(d.confirm.isEnabled())
        d.table.item(1,0).setCheckState(Qt.CheckState.Checked)
        self.assertEqual(d.payload,dict(unit_ids=[2],distance_ids=[20]))
        self.assertIn("48 piezas",d.summary.text())
        d.select_all(True);self.assertEqual(d.payload["distance_ids"],[10,20])
        d.select_all(False);self.assertIsNone(d.payload)
    def test_warehouse_change_clears_selection(self):
        d=self.dialog;d.select_all(True);d.warehouse.setCurrentIndex(1)
        self.assertFalse(d.confirm.isEnabled());self.assertEqual(d.table.rowCount(),1)
        d.select_all(True);self.assertEqual(d.payload["unit_ids"],[3])
    def test_missing_distance_blocks_selected_destination_only(self):
        d=self.dialog;d.state["destinations_by_warehouse"]["1"][1]["km"]=None
        d.table.item(0,0).setCheckState(Qt.CheckState.Checked);self.assertTrue(d.confirm.isEnabled())
        d.select_all(True);self.assertFalse(d.confirm.isEnabled())
