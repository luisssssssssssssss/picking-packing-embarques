"""Daily workload must not confuse future work, stock, or online presence."""
import unittest
from datetime import date, datetime, timezone
from backend.app.services.demo_supervisor import supervisor_view


class SupervisorTests(unittest.TestCase):
    def state(self):
        def task(ident,day,qty,pick,pack,**extra):
            return dict(id=ident,fecha=day,cantidad=qty,recogido=pick,empacado=pack,**extra)
        return dict(tasks=[task(1,"2026-10-01",48,20,10),
                           task(2,"2026-09-30",12,12,2),
                           task(3,"2026-10-02",600,0,0),
                           task(4,"2026-10-01",999,0,0,estado="CANCELLED")],
                    days=[dict(fecha="2026-10-01",capacidad=600,reservado=48)],
                    lines=[dict(fecha="2026-10-01",cantidad=100,planeado=48),
                           dict(fecha="2026-10-02",cantidad=900,planeado=0)],
                    audit=[])

    def test_today_backlog_and_future_are_separate(self):
        result=supervisor_view(self.state(),date(2026,10,1))
        self.assertEqual(result["metrics"],dict(programado=48,empacado=10,recoger=28,listo=20,atraso=10))
        self.assertEqual([r["id"] for r in result["tasks"]],[2,1])
        self.assertEqual(result["sin_programar"],52)
        self.assertEqual(result["capacidad"],600)
        self.assertFalse(result["inventory_known"])

    def test_date_boundary_uses_mexico_not_utc_or_host(self):
        result=supervisor_view(self.state(),now=datetime(2026,10,2,3,tzinfo=timezone.utc))
        self.assertEqual(result["fecha"],"2026-10-01")
        self.assertEqual(result["metrics"]["programado"],48)

    def test_activity_uses_actual_audit_and_does_not_infer_presence(self):
        state=self.state()
        state["audit"]=[dict(accion="PLAN",fecha="2026-10-02T02:00:00"),
                        dict(accion="PICK",fecha="2026-10-02T01:30:00",
                             responsable="Operador demo",detalle='{"message":"Recogidas 20 piezas"}')]
        result=supervisor_view(state,date(2026,10,1))
        self.assertEqual(len(result["activity"]),1)
        self.assertEqual(result["activity"][0]["hora"],"01/10 19:30")
        self.assertEqual(result["activity"][0]["detalle"],"Recogidas 20 piezas")
        self.assertNotIn("online",result)

    def test_empty_day_does_not_imply_capacity_or_stock(self):
        state=dict(tasks=[],days=[],lines=[],audit=[])
        result=supervisor_view(state,date(2026,10,1))
        self.assertIsNone(result["capacidad"])
        self.assertEqual(result["tasks"],[])
        self.assertFalse(result["inventory_known"])

    def test_handoffs_do_not_count_shipped_or_loaded_as_waiting(self):
        state=self.state()
        state["units"]=[dict(estado="PACKED"),dict(estado="STAGED",shipment_id=None),
                        dict(estado="STAGED",shipment_id=4),dict(estado="LOADED",shipment_id=4),
                        dict(estado="SHIPPED",shipment_id=3)]
        result=supervisor_view(state,date(2026,10,1))
        self.assertEqual(result["handoffs"],dict(to_stage=1,waiting_trip=1,to_load=1))
