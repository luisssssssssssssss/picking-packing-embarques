"""Prepare a visible demo scenario once, using the same commands as the desktop."""
from pathlib import Path
from uuid import uuid4
from backend.app.repositories.demo_queries import snapshot
from backend.app.services.demo_commands import execute

def run(action,**payload):
    result=execute(action,payload,uuid4())
    print(result["message"])
    return result

def main():
    if snapshot()["lines"]:
        print("Ya hay pedidos DEMO. Se conservaron sin modificar.")
        return
    content=Path("samples/csv/demo_escritorio.csv").read_text(encoding="utf-8")
    run("import",content=content,filename="demo_escritorio.csv")
    run("plan",start_date="2026-10-05",capacity=600)
    chosen=set()
    for task in snapshot()["tasks"]:
        if task["pedido"] in chosen: continue
        chosen.add(task["pedido"])
        run("pick",id=task["id"],quantity=150,location=task["ubicacion"],material=task["material"])
        result=run("pack",id=task["id"],quantity=100)
        run("stage",id=result["hu_id"])
    run("create_trip")
    hu=max(snapshot()["units"],key=lambda hu:hu["parada"])
    run("load",id=hu["id"],code=hu["codigo"])
    print("Demo lista: trabajo pendiente, tres destinos y un viaje abierto para continuar.")

if __name__=="__main__":
    main()
