"""Configuration and failure-path tests; no SQL Server or real credentials needed."""
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from pydantic import ValidationError
import pyodbc

from backend.app.check_connection import main
from backend.app.core.config import SqlSettings
from backend.app.repositories.connection import build_connection_string, open_connection, SqlConnectionError


class SqlConnectionTests(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, {}, clear=True)
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def settings(self, **values):
        return SqlSettings(_env_file=None, server="localhost", database="WarehouseTest", **values)

    def test_environment_overrides_file_and_password_preserves_symbols(self):
        with tempfile.TemporaryDirectory() as directory:
            env = Path(directory) / ".env"
            env.write_text('SQL_SERVER=file-server\nSQL_DATABASE=Test\nSQL_AUTH_MODE=sql\nSQL_USERNAME=test\nSQL_PASSWORD=" a;}b "\n', encoding="utf-8")
            with patch.dict(os.environ, {"SQL_SERVER": "environment-server"}):
                settings = SqlSettings(_env_file=env)
            self.assertEqual(settings.server, "environment-server")
            self.assertEqual(settings.password.get_secret_value(), " a;}b ")
            self.assertNotIn(" a;}b ", repr(settings))

    def test_invalid_settings_fail_before_connecting(self):
        cases = [
            {"server": " "},
            {"database": ""},
            {"database": "x\x00y"},
            {"login_timeout": 0},
            {"query_timeout": 0},
            {"auth_mode": "sql", "username": "user", "password": ""},
            {"auth_mode": "windows", "password": "not-for-windows"},
        ]
        for values in cases:
            with self.subTest(values=list(values)):
                inputs = {"server": "localhost", "database": "Test", **values}
                with self.assertRaises(ValidationError):
                    SqlSettings(_env_file=None, **inputs)

    def test_odbc_values_cannot_inject_another_setting(self):
        settings = self.settings(auth_mode="sql", username="operator", password="x};Encrypt=no;PWD={y")
        result = build_connection_string(settings)
        self.assertIn("PWD={x}};Encrypt=no;PWD={y};", result)
        self.assertIn("Encrypt={yes};", result)
        self.assertNotIn("Trusted_Connection=", result)

    def test_windows_auth_and_master_are_explicit(self):
        settings = self.settings()
        regular = build_connection_string(settings)
        server = build_connection_string(settings, server_only=True)
        self.assertIn("DATABASE={WarehouseTest};", regular)
        self.assertIn("DATABASE={master};", server)
        self.assertIn("Trusted_Connection={yes};", regular)
        self.assertNotIn("PWD=", regular)
        self.assertIn("TrustServerCertificate={no};", regular)

    @patch("backend.app.repositories.connection.pyodbc.drivers", return_value=[])
    @patch("backend.app.repositories.connection.pyodbc.connect")
    def test_missing_driver_does_not_attempt_connection(self, connect, drivers):
        with self.assertRaises(SqlConnectionError):
            with open_connection(self.settings()):
                self.fail("Should not connect")
        connect.assert_not_called()

    @patch("backend.app.repositories.connection.pyodbc.drivers", return_value=["ODBC Driver 18 for SQL Server"])
    @patch("backend.app.repositories.connection.pyodbc.connect")
    def test_connection_closes_after_query_failure(self, connect, drivers):
        connection = MagicMock()
        connect.return_value = connection
        with self.assertRaises(RuntimeError):
            with open_connection(self.settings()):
                raise RuntimeError("query failed")
        connection.close.assert_called_once()
        connection.commit.assert_not_called()
        self.assertEqual(connection.timeout, 10)

    @patch("backend.app.repositories.connection.pyodbc.drivers", return_value=["ODBC Driver 18 for SQL Server"])
    @patch("backend.app.repositories.connection.pyodbc.connect")
    def test_login_failure_is_redacted_without_fallback(self, connect, drivers):
        connect.side_effect = pyodbc.Error("28000", "Driver leaked PWD=secret-test-value")
        with self.assertRaises(SqlConnectionError) as result:
            with open_connection(self.settings()):
                pass
        self.assertNotIn("secret-test-value", str(result.exception))
        self.assertIn("28000", str(result.exception))
        connect.assert_called_once()
        self.assertIn("DATABASE={WarehouseTest};", connect.call_args.args[0])

    @patch("backend.app.check_connection.SqlSettings")
    def test_invalid_config_cli_hides_input(self, settings):
        settings.side_effect = ValidationError.from_exception_data("Settings", [
            {"type": "int_parsing", "loc": ("login_timeout",), "input": "secret-test-value"}
        ])
        stderr = StringIO()
        with redirect_stderr(stderr):
            self.assertEqual(main([]), 2)
        self.assertNotIn("secret-test-value", stderr.getvalue())

    @patch("backend.app.check_connection.open_connection")
    @patch("backend.app.check_connection.SqlSettings")
    def test_server_probe_does_not_claim_application_database_exists(self, settings, connect):
        settings.return_value = self.settings()
        connection = connect.return_value.__enter__.return_value
        cursor = connection.cursor.return_value
        cursor.execute.return_value.fetchone.return_value = ("test-server", "master", "17.0")
        stdout = StringIO()
        with redirect_stdout(stdout):
            self.assertEqual(main(["--server-only"]), 0)
        result = json.loads(stdout.getvalue())
        self.assertFalse(result["application_database_verified"])
        self.assertEqual(result["connected_database"], "master")
        self.assertEqual(result["configured_database"], "WarehouseTest")
        cursor.close.assert_called_once()

    @patch("backend.app.check_connection.open_connection")
    @patch("backend.app.check_connection.SqlSettings")
    def test_database_failure_returns_nonzero_without_raw_driver_text(self, settings, connect):
        settings.return_value = self.settings()
        connect.return_value.__enter__.side_effect = pyodbc.Error("28000", "PWD=secret-test-value; cannot open database (4060)")
        stderr = StringIO()
        stdout = StringIO()
        with redirect_stderr(stderr), redirect_stdout(stdout):
            self.assertEqual(main([]), 1)
        self.assertNotIn("secret-test-value", stderr.getvalue())
        self.assertIn("base solicitada", stderr.getvalue())
        self.assertEqual(stdout.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
