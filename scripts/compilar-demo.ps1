$ErrorActionPreference='Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
& backend/.venv/Scripts/python.exe -m PyInstaller --noconfirm --windowed --onedir --name AlmacenDemo --distpath dist --workpath .local/pyinstaller --specpath scripts --hidden-import uvicorn.logging --hidden-import uvicorn.loops.asyncio --hidden-import uvicorn.protocols.http.h11_impl --hidden-import uvicorn.lifespan.on desktop_launcher.py
if($LASTEXITCODE -ne 0){throw 'No se pudo compilar la aplicacion.'}
