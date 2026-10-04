"""Installer safety tests; optional real SQL checks use rollback-only fixtures."""
import hashlib
import os
from pathlib import Path
import tempfile
import unittest
from uuid import uuid4

import pyodbc

from backend.app.core.config import SqlSettings
from backend.app.init_database import (
    APP_CODE, MIGRATIONS, Migration, InstallationError,
    apply_migrations, load_migrations, pending_migrations, quote_database,
)
from backend.app.repositories.connection import open_connection


class InstallerTests(unittest.TestCase):
    def test_system_databases_are_rejected(self):
        for name in ("master", "MODEL", " msdb ", "tempdb"):
            with self.subTest(name=name), self.assertRaises(InstallationError):
                quote_database(name)

    def test_identifier_is_quoted_not_interpolated_as_sql(self):
        self.assertEqual(quote_database("demo]; DROP DATABASE other;--"),
                         "[demo]]; DROP DATABASE other;--]")

    def test_unknown_changed_and_out_of_order_history_is_rejected(self):
        migrations = load_migrations()
        for rows in (
            [("999", migrations[0].checksum, APP_CODE)],
            [("001", bytes(32), APP_CODE)],
            [("001", migrations[0].checksum, "OtherApplication")],
            [(m.version, m.checksum, APP_CODE) for m in migrations] + [("999", bytes(32), APP_CODE)],
        ):
            with self.subTest(rows=len(rows)), self.assertRaises(InstallationError):
                pending_migrations(migrations, rows)

    def test_completed_migrations_are_not_reapplied(self):
        migrations = load_migrations()
        rows = [(m.version, m.checksum, APP_CODE) for m in migrations]
        self.assertEqual(pending_migrations(migrations, rows), [])

    def test_windows_line_endings_do_not_change_checksums(self):
        with tempfile.TemporaryDirectory() as tmp:
            for filename in MIGRATIONS:
                Path(tmp, filename).write_bytes(b"SELECT 1;\r\n")
            a = load_migrations(Path(tmp))
            for filename in MIGRATIONS:
                Path(tmp, filename).write_bytes(b"SELECT 1;\n")
            self.assertEqual(a, load_migrations(Path(tmp)))


@unittest.skipUnless(os.environ.get("RUN_SQL_INTEGRATION") == "1", "Explicit SQL test opt-in required")
class SqlIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.settings = SqlSettings()
        if not self.settings.database.endswith(("_Dev", "_Test")):
            self.skipTest("Integration tests restricted to _Dev or _Test databases")
        self.context = open_connection(self.settings)
        self.connection = self.context.__enter__()
        self.addCleanup(self.context.__exit__, None, None, None)
        self.addCleanup(self.connection.rollback)
        self.cursor = self.connection.cursor()
        self.cursor.execute("SET XACT_ABORT OFF; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;")
        self.code = "TEST_" + uuid4().hex[:12]

    def insert(self, table, **values):
        columns = ",".join("["+k+"]" for k in values)
        placeholders = ",".join("?" for _ in values)
        return self.cursor.execute(
            f"INSERT INTO {table} ({columns}) OUTPUT INSERTED.Id VALUES ({placeholders})",
            *values.values(),
        ).fetchone()[0]

    def warehouse(self, suffix):
        point = self.insert("catalog.LogisticsPoint", Code=self.code+suffix, Name="TEST",
                            PointType="WAREHOUSE", IsActive=True)
        return self.insert("catalog.Warehouse", Code=self.code+suffix, Name="TEST",
                           PointId=point, IsActive=True)

    def test_schema_has_all_tables_and_trusted_constraints(self):
        import json
        model = json.loads(Path("database/schema/modelo-logico.json").read_text(encoding="utf-8"))
        tables = {r[0] for r in self.cursor.execute(
            "SELECT SCHEMA_NAME(schema_id)+'.'+name FROM sys.tables WHERE is_ms_shipped=0")}
        self.assertEqual(tables, {t["name"] for t in model["tables"]})
        invalid = self.cursor.execute(
            "SELECT COUNT(*) FROM (SELECT is_disabled,is_not_trusted FROM sys.foreign_keys "
            "UNION ALL SELECT is_disabled,is_not_trusted FROM sys.check_constraints) x "
            "WHERE is_disabled=1 OR is_not_trusted=1").fetchone()[0]
        self.assertEqual(invalid, 0)

    def test_duplicate_catalog_codes_are_rejected(self):
        self.insert("catalog.UnitOfMeasure", Code=self.code, Name="TEST", QuantityScale=0, IsActive=True)
        with self.assertRaises(pyodbc.IntegrityError):
            self.insert("catalog.UnitOfMeasure", Code=self.code, Name="TEST", QuantityScale=0, IsActive=True)

    def test_invalid_scale_and_missing_foreign_key_are_rejected(self):
        with self.assertRaises(pyodbc.IntegrityError):
            self.insert("catalog.UnitOfMeasure", Code=self.code, Name="TEST", QuantityScale=7, IsActive=True)
        with self.assertRaises(pyodbc.IntegrityError):
            self.insert("catalog.Material", Code=self.code, Description="TEST", BaseUnitId=-1,
                        RequiresLot=False, IsActive=True)

    def test_location_cannot_reference_parent_in_other_warehouse(self):
        a, b = self.warehouse("A"), self.warehouse("B")
        parent = self.insert("catalog.Location", WarehouseId=a, Code="ZONE", Name="TEST",
                             LocationType="ZONE", AllowsPicking=False, AllowsStorage=False, IsActive=True)
        with self.assertRaises(pyodbc.IntegrityError):
            self.insert("catalog.Location", WarehouseId=b, ParentLocationId=parent, Code="BIN",
                        Name="TEST", LocationType="BIN", AllowsPicking=True, AllowsStorage=True, IsActive=True)

    def test_capacity_basis_requires_matching_unit_presence(self):
        warehouse = self.warehouse("A")
        with self.assertRaises(pyodbc.IntegrityError):
            self.insert("planning.CapacityPool", WarehouseId=warehouse, Code="PICK",
                        StageCode="PICKING", CapacityBasis="BASE_QUANTITY",
                        TimeZoneId="America/Monterrey", IsActive=True)

    def test_capacity_cannot_be_negative(self):
        warehouse = self.warehouse("A")
        pool = self.insert("planning.CapacityPool", WarehouseId=warehouse, Code="PICK",
                           StageCode="PICKING", CapacityBasis="STANDARD_MINUTES",
                           TimeZoneId="America/Monterrey", IsActive=True)
        actor = self.insert("security.AppUser", Login=self.code, DisplayName="TEST disabled",
                            PasswordHash="DISABLED_TEST_ACCOUNT", IsActive=False, FailedLoginCount=0)
        values = dict(PoolId=pool, WorkDate="2026-10-05", BaseCapacity=600, ExtraCapacity=0,
                      UnavailableCapacity=0, Status="OPEN", ChangeReason="TEST", ChangedBy=actor,
                      WindowStartUtc="2026-10-05 08:00:00", WindowEndUtc="2026-10-05 18:00:00")
        day = self.insert("planning.CapacityDay", **values)
        self.assertGreater(day, 0)
        with self.assertRaises(pyodbc.IntegrityError) as caught:
            self.cursor.execute("UPDATE planning.CapacityDay SET UnavailableCapacity=601 WHERE Id=?", day)
        self.assertIn("(547)", str(caught.exception))

    def test_failed_migration_rolls_back_ddl_and_history(self):
        probe = "platform.__InstallationRollbackProbe"
        self.assertIsNone(self.cursor.execute("SELECT OBJECT_ID(?)", probe).fetchone()[0])
        sql = f"CREATE TABLE {probe} (Id int); THROW 51000, 'Test rollback', 1;"
        next_version = f"{int(load_migrations()[-1].version)+1:03}"
        migration = Migration(next_version, sql, hashlib.sha256(sql.encode()).digest())
        with self.assertRaises(pyodbc.Error):
            try:
                apply_migrations(self.connection, load_migrations()+[migration])
            except Exception:
                self.connection.rollback()
                raise
        self.assertIsNone(self.cursor.execute("SELECT OBJECT_ID(?)", probe).fetchone()[0])
        self.assertEqual(self.cursor.execute(
            "SELECT COUNT(*) FROM platform.SchemaMigration WHERE Version=?", next_version).fetchone()[0], 0)


if __name__ == "__main__":
    unittest.main()
