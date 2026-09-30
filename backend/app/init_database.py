"""Create the configured SQL Server database and apply immutable migrations.

Run from the repository root: python -m backend.app.init_database
No existing data is deleted. Credentials are read only by SqlSettings.
"""
from dataclasses import dataclass
import hashlib
from pathlib import Path
import sys

import pyodbc
from pydantic import ValidationError

from backend.app.core.config import SqlSettings
from backend.app.repositories.connection import open_connection, SqlConnectionError, safe_sql_error

APP_CODE = "PickingPackingEmbarques"
APP_VERSION = "0.2"
MIGRATION_DIR = Path(__file__).resolve().parents[2] / "database" / "migrations"
MIGRATIONS = ("001_tables.sql", "002_relations.sql", "003_integrity.sql", "004_reference_data.sql")


class InstallationError(RuntimeError):
    """Safe, actionable installation failure."""


@dataclass(frozen=True)
class Migration:
    version: str
    sql: str
    checksum: bytes


def quote_database(name: str) -> str:
    if not name.strip() or len(name) > 128 or "\x00" in name:
        raise InstallationError("Nombre de base invalido.")
    if name.strip().casefold() in {"master", "model", "msdb", "tempdb"}:
        raise InstallationError("No se permite instalar en una base del sistema.")
    return "[" + name.replace("]", "]]") + "]"


def load_migrations(directory: Path = MIGRATION_DIR) -> list[Migration]:
    result = []
    for filename in MIGRATIONS:
        data = (directory / filename).read_bytes()
        # Stable checksum across Git checkout CRLF/LF conversions.
        sql = data.decode("utf-8-sig").replace("\r\n", "\n")
        result.append(Migration(filename.split("_", 1)[0], sql, hashlib.sha256(sql.encode("utf-8")).digest()))
    return result


def pending_migrations(migrations: list[Migration], applied: list[tuple]) -> list[Migration]:
    if len(applied) > len(migrations):
        raise InstallationError("La base tiene migraciones mas nuevas que este codigo.")
    for index, row in enumerate(applied):
        version, checksum, application = row
        expected = migrations[index]
        if application != APP_CODE or version != expected.version or bytes(checksum) != expected.checksum:
            raise InstallationError("El historial SQL no coincide con los scripts. No se modifico la base.")
    return migrations[len(applied):]


def apply_migrations(connection: pyodbc.Connection, migrations: list[Migration]) -> list[str]:
    cursor = connection.cursor()
    cursor.execute("SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET CONCAT_NULL_YIELDS_NULL ON; SET ARITHABORT ON; SET NUMERIC_ROUNDABORT OFF;")
    marker = cursor.execute(
        "SELECT CONVERT(nvarchar(128), value) FROM sys.extended_properties "
        "WHERE class=0 AND name=N'ApplicationCode'"
    ).fetchone()
    if marker is None:
        count = cursor.execute("SELECT COUNT(*) FROM sys.objects WHERE is_ms_shipped=0").fetchone()[0]
        if count:
            raise InstallationError("La base contiene objetos ajenos o sin identificacion. Use una base vacia.")
        cursor.execute("EXEC sys.sp_addextendedproperty @name=N'ApplicationCode', @value=?", APP_CODE)
        applied = []
    else:
        if marker[0] != APP_CODE:
            raise InstallationError("La base pertenece a otra aplicacion.")
        if not cursor.execute("SELECT OBJECT_ID(N'platform.SchemaMigration', N'U')").fetchone()[0]:
            raise InstallationError("Falta el registro de migraciones; requiere revision manual.")
        applied = list(cursor.execute(
            "SELECT Version, ScriptChecksum, ApplicationCode FROM platform.SchemaMigration ORDER BY Version"
        ))
    pending = pending_migrations(migrations, applied)
    for migration in pending:
        cursor.execute(migration.sql)
        while cursor.nextset():
            pass
        cursor.execute(
            "INSERT INTO platform.SchemaMigration "
            "(ApplicationCode, Version, ScriptChecksum, AppliedAtUtc, ApplicationVersion) "
            "VALUES (?, ?, ?, SYSUTCDATETIME(), ?)",
            APP_CODE, migration.version, migration.checksum, APP_VERSION,
        )
    connection.commit()
    return [m.version for m in pending]


def initialize(settings: SqlSettings) -> dict:
    database_identifier = quote_database(settings.database)
    migrations = load_migrations()
    # A session lock in master serializes database creation and migration across installers.
    resource = APP_CODE + ":install:" + hashlib.sha256(settings.database.upper().encode("utf-8")).hexdigest()
    with open_connection(settings, server_only=True) as master:
        master.autocommit = True
        lock = master.cursor().execute(
            "DECLARE @result int; EXEC @result=sys.sp_getapplock "
            "@Resource=?, @LockMode='Exclusive', @LockOwner='Session', @LockTimeout=0; SELECT @result;",
            resource,
        ).fetchone()[0]
        if lock < 0:
            raise InstallationError("Otra instalacion esta en curso. Intente de nuevo al terminar.")
        try:
            exists = master.cursor().execute("SELECT DB_ID(?)", settings.database).fetchone()[0]
            if exists is None:
                master.cursor().execute("CREATE DATABASE " + database_identifier)
            with open_connection(settings) as connection:
                try:
                    applied = apply_migrations(connection, migrations)
                except Exception:
                    connection.rollback()
                    raise
        finally:
            master.cursor().execute(
                "EXEC sys.sp_releaseapplock @Resource=?, @LockOwner='Session';", resource
            )
    return {"database": settings.database, "created": exists is None, "applied": applied}


def main() -> int:
    try:
        result = initialize(SqlSettings())
    except (InstallationError, SqlConnectionError) as error:
        print(str(error), file=sys.stderr)
        return 1
    except pyodbc.Error as error:
        print(safe_sql_error(error), file=sys.stderr)
        return 1
    except (ValidationError, OSError, UnicodeError):
        print("Revise la configuracion local y los archivos de migracion.", file=sys.stderr)
        return 1
    print(f"Base: {result['database']}")
    print("Base creada." if result["created"] else "Base existente conservada.")
    print("Migraciones aplicadas: " + (", ".join(result["applied"]) or "ninguna; ya esta actualizada."))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
