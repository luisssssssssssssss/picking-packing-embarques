"""Import validated simulation orders into the existing staging and operation tables."""
from collections import defaultdict
from datetime import date
from decimal import Decimal
import hashlib
from pathlib import Path
import os
from backend.app.integrations.demo_csv import parse_csv
from backend.app.repositories.demo import BusinessError, dump, now

def import_orders(db, ctx, payload, operation):
    content=payload["content"]
    rows,errors=parse_csv(content)
    digest=hashlib.sha256(content.encode("utf-8")).digest()
    existing=db.one("SELECT Id FROM integration.ImportedFile WHERE SourceSystemId=? AND ContentHash=?",ctx["source"],digest)
    if existing:
        return dict(message="Este archivo ya fue registrado; no se duplicaron pedidos.",duplicate=True)
    groups=defaultdict(list)
    for item in rows:
        d=item["data"]; groups[d["NumeroPedido"]].append(item)
        material=db.one("SELECT Id,Description FROM catalog.Material WHERE Code=? AND IsActive=1",d["CodigoMaterial"])
        destination=db.one("SELECT ds.Id,c.Id AS CustomerId FROM catalog.DeliverySite ds JOIN catalog.Customer c ON c.Id=ds.CustomerId WHERE ds.Code=? AND c.Code=?",d["CodigoDestino"],d["CodigoCliente"])
        if not material or not d["CodigoMaterial"].startswith("DEMO-"):
            errors.append(dict(line=item["number"],message="Material fuera del catálogo DEMO"))
        if not destination or not d["CodigoDestino"].startswith("DEMO-"):
            errors.append(dict(line=item["number"],message="Cliente y destino no coinciden con el catálogo DEMO"))
        item["material"]=material; item["destination"]=destination
    for number,items in groups.items():
        if len({i["data"]["CodigoCliente"] for i in items})>1:
            errors.append(dict(line=items[0]["number"],message="Un pedido no puede mezclar clientes"))
        if db.one("SELECT Id FROM operations.SalesOrder WHERE SourceSystemId=? AND ExternalOrderNumber=?",ctx["source"],number):
            errors.append(dict(line=items[0]["number"],message="El pedido ya existe. La demo no reemplaza revisiones; usa otro número."))
    # Persist source evidence outside Git; hash path prevents traversal.
    directory=Path(os.environ.get("PPE_PROJECT_ROOT",str(Path(__file__).resolve().parents[3])))/".local"/"imports"
    directory.mkdir(parents=True,exist_ok=True)
    path=directory/(digest.hex()+".csv")
    path.write_text(content,encoding="utf-8")
    file_id=db.insert("integration.ImportedFile",SourceSystemId=ctx["source"],ContentHash=digest,
                      ByteLength=len(content.encode("utf-8")),OriginalFileName=Path(payload.get("filename","demo.csv")).name[:240],
                      StorageKey="imports/"+path.name,UploadedBy=ctx["actor"])
    run=db.insert("integration.ImportRun",FileId=file_id,ProfileVersionId=ctx["profile"],AttemptNumber=1,RequestedBy=ctx["actor"],
                  Status="FAILED" if errors else "COMPLETED",StartedAtUtc=now(),FinishedAtUtc=now())
    # Demo uses an explicit all-or-nothing file policy, including cross-row errors.
    if errors:
        for item in rows:
            db.insert("integration.ImportRow",RunId=run,RecordNumber=item["number"],PhysicalLineStart=item["number"],
                      PhysicalLineEnd=item["number"],RawText=dump(item["data"]),ParsedJson=dump(item["data"]),Status="INVALID")
        for error in errors:
            db.insert("integration.ImportError",RunId=run,Severity="ERROR",ErrorCode="DEMO_VALIDATION",
                      Message=f"Fila {error['line']}: {error['message']}")
        return dict(message="Archivo rechazado. Ningún pedido fue incorporado.",errors=errors,run_id=run)
    for number,items in groups.items():
        oid=db.insert("operations.SalesOrder",SourceSystemId=ctx["source"],ExternalOrderNumber=number,
                      CustomerId=items[0]["destination"]["CustomerId"],Status="CREATED")
        revision=db.insert("operations.OrderRevision",OrderId=oid,RevisionNumber=1,
                           BusinessContentHash=hashlib.sha256(dump([i["data"] for i in items]).encode()).digest(),
                           ChangeReason="Importación CSV simulada",AcceptedBy=ctx["actor"])
        db.execute("UPDATE operations.SalesOrder SET CurrentRevisionId=?,UpdatedAtUtc=SYSUTCDATETIME() WHERE Id=?",revision,oid)
        result=db.insert("integration.ImportOrderResult",RunId=run,ExternalOrderNumber=number,Status="APPLIED",OrderRevisionId=revision)
        for item in items:
            d=item["data"]
            line=db.insert("operations.OrderLine",OrderId=oid,ExternalLineKey=d["LineaPedido"],IsClosed=False)
            qty=Decimal(d["CantidadSolicitada"])
            db.insert("operations.OrderLineRevision",OrderId=oid,OrderRevisionId=revision,OrderLineId=line,
                      MaterialId=item["material"]["Id"],DeliverySiteId=item["destination"]["Id"],RequestedUnitId=ctx["unit"],
                      RequestedQuantity=qty,FactorToBase=1,RequiredBaseQuantity=qty,RequestedDate=date.fromisoformat(d["FechaRequeridaEntrega"]),
                      Priority=2,IsCancelled=False,MaterialCodeSnapshot=d["CodigoMaterial"],MaterialDescriptionSnapshot=item["material"]["Description"])
            db.insert("integration.ImportRow",RunId=run,OrderResultId=result,RecordNumber=item["number"],
                      PhysicalLineStart=item["number"],PhysicalLineEnd=item["number"],RawText=dump(d),ParsedJson=dump(d),
                      Status="APPLIED",AppliedOrderLineId=line)
    return dict(message=f"{len(groups)} pedidos y {len(rows)} líneas importados.",run_id=run,errors=[])
