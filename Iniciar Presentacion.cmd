@echo off
setlocal
cd /d "%~dp0"
set "SQL_DATABASE=PickingPackingEmbarques_Presentacion_20261004_Dev"
if not exist "backend\.venv\Scripts\pythonw.exe" (
 echo Prepara primero el entorno Python del proyecto.
 pause
 exit /b 1
)
"backend\.venv\Scripts\python.exe" -m backend.app.init_database
if errorlevel 1 (
 pause
 exit /b 1
)
start "" "backend\.venv\Scripts\pythonw.exe" "%~dp0desktop_launcher.py" --supervisor
endlocal
