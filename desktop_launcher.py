"""Desktop entry point: launches one private loopback API and the native Qt window."""
import atexit
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import time

def project_root():
    if os.environ.get("PPE_PROJECT_ROOT"):
        return Path(os.environ["PPE_PROJECT_ROOT"]).resolve()
    if getattr(sys,"frozen",False):
        # dist/AlmacenDemo/AlmacenDemo.exe in the development repository.
        return Path(sys.executable).resolve().parents[2]
    return Path(__file__).resolve().parent

def main():
    root=project_root()
    os.environ["PPE_PROJECT_ROOT"]=str(root)
    os.environ.setdefault("PPE_ENV_FILE",str(root/"backend"/".env"))
    if "--backend" in sys.argv:
        import uvicorn
        from backend.app.main import app
        uvicorn.run(app,host="127.0.0.1",port=int(os.environ["PPE_API_PORT"]),
                    loop="asyncio",http="h11",ws="none",log_config=None,access_log=False)
        return
    from PySide6.QtWidgets import QApplication,QMessageBox
    from PySide6.QtCore import QTimer
    from frontend.desktop.operator_window import OperatorWindow
    import httpx
    application=QApplication(sys.argv)
    application.setStyle("Fusion")
    application.setApplicationName("Almacén · Demo")
    if not (root/"backend"/".env").exists():
        QMessageBox.critical(None,"Configuración pendiente","No se encontró backend/.env. Consulta docs/demo-escritorio.md.")
        return
    with socket.socket() as sock:
        sock.bind(("127.0.0.1",0))
        port=sock.getsockname()[1]
    os.environ["PPE_API_PORT"]=str(port)
    os.environ["PPE_API_URL"]=f"http://127.0.0.1:{port}"
    os.environ["PPE_DEMO_TOKEN"]=secrets.token_urlsafe(40)
    local=root/".local";local.mkdir(exist_ok=True)
    log=(local/"desktop-api.log").open("a",encoding="utf-8")
    cmd=[sys.executable,"--backend"] if getattr(sys,"frozen",False) else [sys.executable,str(Path(__file__).resolve()),"--backend"]
    process=subprocess.Popen(cmd,cwd=root,env=os.environ.copy(),stdout=log,stderr=log,
                             creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
    def stop():
        if process.poll() is None:
            process.terminate()
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired: process.kill()
        log.close()
    atexit.register(stop)
    ready=False
    with httpx.Client(timeout=1,trust_env=False) as client:
        for _ in range(100):
            if process.poll() is not None: break
            try:
                r=client.get(os.environ["PPE_API_URL"]+"/health",headers={"Authorization":"Bearer "+os.environ["PPE_DEMO_TOKEN"]})
                if r.status_code==200:ready=True;break
            except httpx.HTTPError:pass
            time.sleep(.2)
    if not ready:
        QMessageBox.critical(None,"No se pudo iniciar","Revisa que SQL Server esté encendido y backend/.env sea correcto. Diagnóstico: .local/desktop-api.log")
        stop();return
    window=OperatorWindow();window.show()
    if "--supervisor" in sys.argv:
        def open_supervisor():
            if window.jobs or not window.state:
                QTimer.singleShot(200,open_supervisor)
                return
            window.open_admin()
        QTimer.singleShot(200,open_supervisor)
    if "--capture" in sys.argv:
        attempts=[0]
        def capture():
            attempts[0]+=1
            if window.state and not window.jobs and ("--supervisor" not in sys.argv or (window.admin and window.admin.state and not window.admin.jobs)):
                folder=root/"docs"/"pruebas"/"capturas";folder.mkdir(exist_ok=True)
                if "--supervisor" in sys.argv:
                    window.admin.grab().save(str(folder/"demo-supervisor.png"))
                    application.quit()
                    return
                window.grab().save(str(folder/"demo-operador.png"))
                window.resize(390,780);application.processEvents()
                window.grab().save(str(folder/"demo-operador-compacto.png"))
                application.quit()
            elif attempts[0]<100:QTimer.singleShot(200,capture)
            else:application.quit()
        QTimer.singleShot(500,capture)
    result=application.exec()
    stop()
    return result

if __name__=="__main__":
    raise SystemExit(main())
