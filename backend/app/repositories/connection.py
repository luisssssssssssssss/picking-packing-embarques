"""SQL Server connections. No schema changes or automatic database fallback."""
from collections.abc import Iterator
from contextlib import contextmanager
import re

import pyodbc

from backend.app.core.config import SqlSettings


class SqlConnectionError(RuntimeError):
    """A safe diagnostic that never includes the original connection string."""


def _odbc_value(value: str) -> str:
    # Braces protect semicolons; a closing brace inside a value is doubled.
    if "\x00" in value:
        raise ValueError("Un valor ODBC no puede contener caracteres nulos.")
    return "{" + value.replace("}", "}}") + "}"


def build_connection_string(settings: SqlSettings, *, server_only: bool = False) -> str:
    """Contains credentials when using SQL auth. Never print or log its result."""
    values = {
        "DRIVER": settings.driver,
        "SERVER": settings.server,
        "DATABASE": "master" if server_only else settings.database,
        "Encrypt": "yes" if settings.encrypt else "no",
        "TrustServerCertificate": "yes" if settings.trust_server_certificate else "no",
        "APP": "PickingPackingEmbarques",
    }
    if settings.auth_mode == "windows":
        values["Trusted_Connection"] = "yes"
    else:
        values["UID"] = settings.username
        values["PWD"] = settings.password.get_secret_value()
    return ";".join(f"{key}={_odbc_value(value)}" for key, value in values.items()) + ";"


def safe_sql_error(error: pyodbc.Error) -> str:
    # Driver diagnostics can contain credentials or connection strings.
    candidate = error.args[0] if error.args else ""
    state = candidate if isinstance(candidate, str) and re.fullmatch(r"[A-Z0-9]{5}", candidate) else "?????"
    native_codes = {
        code
        for argument in error.args[1:]
        if isinstance(argument, str)
        for code in re.findall(r"\((\d+)\)", argument)
    }
    if native_codes & {"4060", "916", "911"}:
        message = "No se pudo abrir la base solicitada: puede no existir o faltar permisos."
    elif state.startswith("28"):
        message = "SQL Server rechazo la autenticacion. Revise el modo y las credenciales."
    elif state in {"HYT00", "HYT01"}:
        message = "Se agoto el tiempo de espera. Revise instancia, servicio y conectividad."
    elif state.startswith("08"):
        message = "No se pudo establecer la conexion. Revise instancia, red y certificado."
    elif state in {"IM002", "IM003"}:
        message = "No se pudo cargar el controlador ODBC configurado."
    elif state == "42000":
        message = "SQL Server rechazo el acceso o la consulta. Revise la base y los permisos."
    else:
        message = "No se pudo completar la operacion SQL. Revise configuracion y permisos."
    return f"{message} SQLSTATE={state}."


@contextmanager
def open_connection(settings: SqlSettings, *, server_only: bool = False) -> Iterator[pyodbc.Connection]:
    """Caller must explicitly commit future writes. The connection always closes."""
    if settings.driver not in pyodbc.drivers():
        raise SqlConnectionError("El controlador ODBC configurado no esta instalado para este Python.")
    try:
        connection = pyodbc.connect(
            build_connection_string(settings, server_only=server_only),
            timeout=settings.login_timeout,
            autocommit=False,
        )
    except pyodbc.Error as error:
        raise SqlConnectionError(safe_sql_error(error)) from None
    try:
        connection.timeout = settings.query_timeout
        yield connection
    finally:
        connection.close()
