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

:: Ensure all backend deps are installed (server + cli extras from pyproject).
echo Проверяю зависимости (первый запуск может занять пару минут)...
call uv sync --extra server --extra cli
if errorlevel 1 (
    echo.
    echo ОШИБКА: uv sync не удался. Проверь интернет.
    pause
    exit /b 1
)

:: Launch backend + frontend via the project venv (uv sync above ensured it exists).
.venv\Scripts\python.exe scripts/start_web.py
