"""Planning must use Saturday capacity and include Sunday."""
import unittest
from unittest.mock import patch
from datetime import date
from backend.app.services.demo_warehouse import plan


class CalendarTests(unittest.TestCase):
    def test_saturday_overflow_continues_on_sunday(self):
        from unittest.mock import MagicMock
        db=MagicMock()
        db.rows.return_value=[dict(cantidad=1000,planeado=0,id=1,revision_id=1,MaterialId=1)]
        db.scalar.side_effect=[600,1,0,600,1]
        db.insert.return_value=1
        dates=[]
        def capacity_day(db,ctx,work,capacity):
            dates.append(work)
            return 1
        ctx=dict(pool=1,warehouse=1,actor=1,locations={"BIN":1})
        with patch("backend.app.services.demo_warehouse.day",side_effect=capacity_day), patch("backend.app.services.demo_familiar.warehouse_context",return_value=ctx):
            plan(db,ctx,dict(start_date="2026-10-03",capacity=600),1)
        self.assertEqual(dates,[date(2026,10,3),date(2026,10,3),date(2026,10,4)])
        allocations=[c.kwargs["AllocatedBaseQuantity"] for c in db.insert.call_args_list
                     if c.args[0]=="operations.FulfillmentAllocation"]
        self.assertEqual(allocations,[600,400])
