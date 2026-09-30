"""SQL helpers for the local, isolated demonstration workflow."""
from contextlib import contextmanager
from datetime import datetime, timezone
from decimal import Decimal
import json
import re

from backend.app.core.config import SqlSettings
from backend.app.repositories.connection import open_connection

class BusinessError(ValueError):
    pass

def now():
    return datetime.now(timezone.utc).replace(tzinfo=None)

def encode(value):
    if isinstance(value, Decimal):
        return float(value)
    if hasattr(value, "isoformat"):
        return value.isoformat()
    raise TypeError(type(value).__name__)

def dump(value):
    return json.dumps(value, ensure_ascii=False, default=encode, sort_keys=True)

class Store:
    def __init__(self, connection):
        self.connection = connection
        self.cursor = connection.cursor()

    def rows(self, sql, *args):
        result = self.cursor.execute(sql, *args)
        names = [c[0] for c in result.description]
        return [dict(zip(names, row)) for row in result.fetchall()]

    def one(self, sql, *args):
        rows = self.rows(sql, *args)
        return rows[0] if rows else None

    def scalar(self, sql, *args):
        return self.cursor.execute(sql, *args).fetchone()[0]

    def execute(self, sql, *args):
        return self.cursor.execute(sql, *args)

    def insert(self, table, **values):
        # Names are internal constants; values always use bound parameters.
        if not re.fullmatch(r"[a-z]+\.[A-Za-z]+", table):
            raise ValueError("Invalid internal table name")
        fields = ",".join("["+name+"]" for name in values)
        slots = ",".join("?" for _ in values)
        return self.scalar(f"INSERT INTO {table} ({fields}) OUTPUT INSERTED.Id VALUES ({slots})", *values.values())

@contextmanager
def transaction(write=True):
    settings = SqlSettings()
    if not settings.database.endswith(("_Dev", "_Test")):
        raise BusinessError("La demo solo funciona en una base _Dev o _Test.")
    with open_connection(settings) as connection:
        connection.timeout = 30
        db = Store(connection)
        db.execute("SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;")
        try:
            if write:
                code = db.scalar("DECLARE @r int; EXEC @r=sys.sp_getapplock @Resource='PPE:desktop-demo', @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=10000; SELECT @r;")
                if code < 0:
                    raise BusinessError("Otra operación está en curso. Vuelve a intentarlo.")
            yield db
            connection.commit()
        except Exception:
            connection.rollback()
            raise
