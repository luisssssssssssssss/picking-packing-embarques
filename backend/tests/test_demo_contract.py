"""Parser and HTTP authorization tests for the desktop contract."""
from pathlib import Path
import os
import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.integrations.demo_csv import parse_csv

class CsvTests(unittest.TestCase):
    def setUp(self):
        self.sample=Path("samples/csv/demo_escritorio.csv").read_text(encoding="utf-8")
    def test_valid_contract(self):
        rows,errors=parse_csv(self.sample)
        self.assertEqual(len(rows),3);self.assertEqual(errors,[])
    def test_missing_column(self):
        self.assertTrue(parse_csv(self.sample.replace("LineaPedido,","",1))[1])
    def test_duplicate_order_line(self):
        self.assertTrue(parse_csv(self.sample+self.sample.splitlines()[1]+"\n")[1])
    def test_invalid_quantities(self):
        for value in ("0","-1","NaN","Infinity","2.5"):
            with self.subTest(value=value):
                self.assertTrue(parse_csv(self.sample.replace(",1000,PZA",f",{value},PZA"))[1])
    def test_bad_date_and_empty_file(self):
        self.assertTrue(parse_csv(self.sample.replace("2026-10-05","31/99/2026"))[1])
        self.assertTrue(parse_csv("")[1])
    def test_non_demo_order_rejected(self):
        self.assertTrue(parse_csv(self.sample.replace("DEMO-450001","450001"))[1])

class ApiTests(unittest.TestCase):
    def test_no_anonymous_access_to_data_or_commands(self):
        client=TestClient(app)
        for path in ("/demo/operator","/demo/snapshot","/demo/sample","/demo/shipments/1/manifest"):
            self.assertEqual(client.get(path).status_code,401)
        self.assertEqual(client.post("/demo/commands/plan",json={"key":"00000000-0000-0000-0000-000000000001","payload":{}}).status_code,401)
    def test_authenticated_sample_and_health_without_database_mutation(self):
        token="test-local-token-"+"x"*32
        with patch.dict(os.environ,{"PPE_DEMO_TOKEN":token}):
            client=TestClient(app,headers={"Authorization":"Bearer "+token})
            self.assertEqual(client.get("/health").status_code,200)
            result=client.get("/demo/sample")
            self.assertEqual(result.status_code,200)
            self.assertIn("DEMO-450001",result.json()["content"])

if __name__=="__main__": unittest.main()
