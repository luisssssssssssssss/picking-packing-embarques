"""Read-only diagnostic. Run from repository root with -m backend.app.check_connection."""
import argparse
from contextlib import closing
import json
import sys

from pydantic import ValidationError
from pydantic_settings.exceptions import SettingsError
import pyodbc

from backend.app.core.config import SqlSettings
from backend.app.repositories.connection import (
    SqlConnectionError,
    open_connection,
    safe_sql_error,
)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Comprobar SQL Server sin crear bases ni tablas.")
    parser.add_argument(
        "--server-only",
        action="store_true",
        help="Conectar explicitamente a master; no comprueba la base del proyecto.",
    )
    args = parser.parse_args(argv)
    try:
        settings = SqlSettings()
    except (ValidationError, SettingsError, OSError):
        print("Configuracion SQL invalida. Revise backend/.env y las variables SQL_ del entorno.", file=sys.stderr)
        return 2

    try:
        with open_connection(settings, server_only=args.server_only) as connection:
            with closing(connection.cursor()) as cursor:
                row = cursor.execute(
                    "SELECT CAST(SERVERPROPERTY('ServerName') AS nvarchar(128)), "
                    "DB_NAME(), CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128))"
                ).fetchone()
        print(json.dumps({
            "status": "ok",
            "scope": "server" if args.server_only else "database",
            "server": row[0],
            "connected_database": row[1],
            "product_version": row[2],
            "configured_database": settings.database,
            "application_database_verified": not args.server_only,
        }, ensure_ascii=False, indent=2))
        return 0
    except SqlConnectionError as error:
        print(str(error), file=sys.stderr)
        return 1
    except pyodbc.Error as error:
        print(safe_sql_error(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
