@echo off
title DeepTutor
cd /d "%~dp0"

:: If already running, just open the browser and exit
netstat -ano | findstr ":3782 .*LISTENING" >nul 2>&1
if %errorlevel%==0 (
    start http://localhost:3782
    exit /b
)

:: Open browser after a short delay (frontend needs ~3s to boot)
start "" cmd /c "timeout /t 5 /nobreak >nul & start http://localhost:3782"

:: Ensure server extras are installed (uvicorn/fastapi live in optional-deps)
uv sync --extra server >nul 2>&1

:: Launch backend + frontend via the project launcher
uv run --extra server python scripts/start_web.py
