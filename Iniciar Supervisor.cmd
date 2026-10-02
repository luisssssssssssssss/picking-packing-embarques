@echo off
set "PPE_PROJECT_ROOT=%~dp0"
cd /d "%~dp0"
if not exist "%~dp0backend\.venv\Scripts\pythonw.exe" (
    echo Primero prepara el entorno Python siguiendo docs\demo-escritorio.md
    pause
    exit /b 1
)
start "" "%~dp0backend\.venv\Scripts\pythonw.exe" "%~dp0desktop_launcher.py" --supervisor
