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

:: Ensure all backend deps are installed (server extras + CLI requirements)
:: server extras = fastapi/uvicorn (in pyproject optional-deps)
:: cli.txt = llama_index and other runtime libs (not in pyproject)
echo Проверяю зависимости (первый запуск может занять пару минут)...
call uv sync --extra server
if errorlevel 1 (
    echo.
    echo ОШИБКА: uv sync не удался. Проверь интернет.
    pause
    exit /b 1
)
:: Activate project venv so `uv pip install` targets it (not system Python)
call .venv\Scripts\activate.bat
call uv pip install -r requirements/cli.txt
if errorlevel 1 (
    echo.
    echo ОШИБКА: установка cli.txt не удалась.
    pause
    exit /b 1
)

:: Launch backend + frontend via the project venv directly.
:: NOTE: do NOT use `uv run` here — it re-syncs the venv against pyproject.toml
:: and would uninstall packages from requirements/cli.txt (e.g. llama_index).
.venv\Scripts\python.exe scripts/start_web.py
