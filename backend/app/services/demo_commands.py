"""Atomic, idempotent commands; every accepted action has SQL audit evidence."""
import hashlib
import json
from uuid import UUID
from backend.app.repositories.demo import BusinessError, transaction, now, dump
from backend.app.services.demo_seed import seed
from backend.app.services.demo_import import import_orders
from backend.app.services.demo_warehouse import plan,pick,pack,stage,incident
from backend.app.services.demo_shipping import create_trip,load,close

from backend.app.services.demo_catalog import save_destination,create_order

ACTIONS={"save_destination":save_destination,"create_order":create_order,"import":import_orders,"plan":plan,"pick":pick,"pack":pack,"stage":stage,
         "create_trip":create_trip,"load":load,"close":close,"incident":incident}

def execute(action,payload,key,operator=False):
    if action not in ACTIONS: raise BusinessError("Acción desconocida.")
    try: UUID(str(key))
    except ValueError: raise BusinessError("Identificador de operación inválido.") from None
    digest=hashlib.sha256(dump(dict(action=action,payload=payload)).encode()).digest()
    with transaction() as db:
        ctx=seed(db)
        if not db.scalar("SELECT IsActive FROM security.AppUser WHERE Id=?",ctx["actor"]):
            raise BusinessError("El usuario de demostración está deshabilitado.")
        previous=db.one("SELECT RequestHash,ResultJson FROM platform.OperationRequest WHERE ActorUserId=? AND IdempotencyKey=?",ctx["actor"],str(key))
        if previous:
            if bytes(previous["RequestHash"])!=digest:
                raise BusinessError("El identificador ya se usó con otros datos.")
            return json.loads(previous["ResultJson"])
        if operator:
            from backend.app.services.demo_operator_calendar import validate_operator_day
            validate_operator_day(db,action,payload)
        operation=db.insert("platform.OperationRequest",ActorUserId=ctx["actor"],IdempotencyKey=str(key),
                            OperationCode="DEMO_"+action.upper(),RequestHash=digest,Outcome="SUCCEEDED",
                            ResponseCode=200,ResultJson="{}",CompletedAtUtc=now())
        result=ACTIONS[action](db,ctx,payload,operation)
        db.execute("UPDATE platform.OperationRequest SET ResultJson=?,CompletedAtUtc=SYSUTCDATETIME() WHERE Id=?",dump(result),operation)
        db.insert("audit.AuditEvent",OperationId=operation,ActorUserId=ctx["actor"],ActionCode=action.upper(),
                  EntityType="DESKTOP_DEMO",EntityKey=str(payload.get("id",result.get("run_id",operation))),
                  Outcome="SUCCEEDED",AfterJson=dump(result),Reason="Demostración ficticia de escritorio",
                  CorrelationId=str(key),OccurredAtUtc=now())
        return json.loads(dump(result))
