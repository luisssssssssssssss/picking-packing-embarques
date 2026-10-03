"""Loopback-only demonstration API. Desktop clients never receive SQL credentials."""
from contextlib import asynccontextmanager
import hmac
import logging
import os
from pathlib import Path
from typing import Annotated
from uuid import UUID
import pyodbc
from fastapi import FastAPI,Header,HTTPException,Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel,Field
from backend.app.repositories.demo import BusinessError
from backend.app.repositories.connection import SqlConnectionError
from backend.app.repositories.demo_queries import snapshot
from backend.app.services.demo_seed import bootstrap
from backend.app.services.demo_commands import execute

def authorize(authorization: Annotated[str|None,Header()]=None):
    token=os.environ.get("PPE_DEMO_TOKEN","")
    if len(token)<32 or not authorization or not hmac.compare_digest(authorization,"Bearer "+token):
        raise HTTPException(401,"Abre la aplicación con Iniciar Demo para autorizar la sesión local.")

@asynccontextmanager
async def lifespan(app):
    if len(os.environ.get("PPE_DEMO_TOKEN",""))<32:
        raise RuntimeError("Falta un token local seguro; use scripts.launch_demo.")
    bootstrap()
    yield

app=FastAPI(title="Almacén · Demo local",lifespan=lifespan,docs_url=None,redoc_url=None)

class Command(BaseModel):
    key:UUID
    payload:dict=Field(default_factory=dict)

@app.exception_handler(BusinessError)
async def business_error(request,error):
    return JSONResponse(status_code=409,content={"detail":str(error)})

@app.exception_handler(pyodbc.Error)
async def sql_error(request,error):
    logging.error("SQL operation failed (driver details withheld).")
    return JSONResponse(status_code=503,content={"detail":"No se pudo completar la operación en SQL. Los cambios se revirtieron."})

@app.exception_handler(SqlConnectionError)
async def connection_error(request,error):
    return JSONResponse(status_code=503,content={"detail":str(error)})

@app.get("/health",dependencies=[Depends(authorize)])
def health():
    return {"status":"ok","mode":"desktop-demo"}

@app.get("/demo/snapshot",dependencies=[Depends(authorize)])
def get_snapshot():
    return snapshot()

@app.get("/demo/operator",dependencies=[Depends(authorize)])
def get_operator(preferred_allocation: int | None = None):
    from backend.app.services.demo_operator import operator_view
    return operator_view(snapshot(),preferred_allocation)


@app.get("/demo/sample",dependencies=[Depends(authorize)])
def sample():
    path=Path(os.environ.get("PPE_PROJECT_ROOT",str(Path(__file__).resolve().parents[2])))/"samples"/"csv"/"demo_escritorio.csv"
    return {"filename":path.name,"content":path.read_text(encoding="utf-8-sig")}

@app.post("/demo/commands/{action}",dependencies=[Depends(authorize)])
def command(action:str,body:Command):
    # A local demonstration contract: reject huge payloads before parsing.
    import json
    if len(json.dumps(body.payload))>1_500_000: raise HTTPException(413,"Archivo demasiado grande.")
    try:
        return execute(action,body.payload,body.key)
    except (KeyError,TypeError,ValueError) as error:
        if isinstance(error,BusinessError): raise
        raise HTTPException(422,"Faltan datos o tienen un formato inválido.") from None


@app.get("/demo/shipments/{ident}/manifest",dependencies=[Depends(authorize)])
def manifest(ident:int):
    import json
    from backend.app.repositories.demo import transaction
    with transaction(False) as db:
        row=db.one("SELECT sc.ManifestJson FROM shipping.ShipmentClosure sc JOIN shipping.Shipment s ON s.Id=sc.ShipmentId JOIN planning.Trip t ON t.Id=s.TripId WHERE s.Id=? AND t.Code LIKE 'DEMO-VIA-%'",ident)
        if not row: raise HTTPException(404,"El manifiesto estará disponible al cerrar el viaje.")
        return json.loads(row["ManifestJson"])
