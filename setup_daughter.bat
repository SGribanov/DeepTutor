@echo off
chcp 65001 >nul
title Установка DeepTutor
cd /d "%~dp0"

echo.
echo  ╔═══════════════════════════════════════════╗
echo  ║                                           ║
echo  ║     Установка DeepTutor                   ║
echo  ║     Это займёт 5-10 минут                 ║
echo  ║                                           ║
echo  ╚═══════════════════════════════════════════╝
echo.

:: ── Check admin ─────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Нужны права администратора для установки программ.
    echo  Нажми правой кнопкой → «Запуск от имени администратора»
    echo.
    pause
    exit /b 1
)

:: ── 1. Copy project ─────────────────────────────────────
echo [1/7] Копирую проект в C:\Repos\DeepTutor ...
if not exist "C:\Repos" mkdir "C:\Repos"
if exist "%~dp0DeepTutor" (
    robocopy "%~dp0DeepTutor" "C:\Repos\DeepTutor" /mir /njh /njs /ndl /nc /ns /np >nul
    echo        OK
) else (
    echo        Папка DeepTutor не найдена рядом с этим скриптом!
    pause
    exit /b 1
)

cd /d "C:\Repos\DeepTutor"

:: ── Helper: refresh PATH in current session ─────────────
:: After installs, new tools won't be on PATH until we reload it
set "REFRESH_PATH=for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B" & for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B" & set "PATH=%SYS_PATH%;%USR_PATH%""

:: ── 2. Install Node.js ──────────────────────────────────
echo.
echo [2/7] Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo        Устанавливаю Node.js...
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent
    :: Refresh PATH
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
    set "PATH=%SYS_PATH%;%USR_PATH%"
)
where node >nul 2>&1 && echo        OK || echo        ОШИБКА: node не найден после установки

:: ── 3. Install Ollama ───────────────────────────────────
echo.
echo [3/7] Ollama...
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    echo        Устанавливаю Ollama...
    winget install Ollama.Ollama --accept-package-agreements --accept-source-agreements --silent
    for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
    set "PATH=%SYS_PATH%;%USR_PATH%"
)
where ollama >nul 2>&1 && echo        OK || echo        ОШИБКА: ollama не найдена после установки

:: ── 4. Install uv ───────────────────────────────────────
echo.
echo [4/7] uv (менеджер Python)...
where uv >nul 2>&1
if %errorlevel% neq 0 (
    echo        Устанавливаю uv...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex" >nul 2>&1
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
    set "PATH=%PATH%;%USR_PATH%;%USERPROFILE%\.local\bin;%USERPROFILE%\.cargo\bin"
)
where uv >nul 2>&1 && echo        OK || echo        ОШИБКА: uv не найден после установки

:: ── 5. Python dependencies ──────────────────────────────
echo.
echo [5/7] Python-зависимости...
call uv sync --extra server --extra cli
if errorlevel 1 (
    echo        ОШИБКА: uv sync не удался. Проверь интернет и запусти установщик снова.
    pause
    exit /b 1
)
echo        OK

:: ── 6. Node dependencies + Ollama model ─────────────────
echo.
echo [6/7] Node-зависимости и модель эмбеддингов...
cd web
call npm install --loglevel=error
cd ..
echo        npm OK

:: Start Ollama service if not running, then pull model
start /b ollama serve >nul 2>&1
timeout /t 2 /nobreak >nul
ollama pull nomic-embed-text
echo        ollama OK

:: ── 7. Desktop shortcut ─────────────────────────────────
echo.
echo [7/7] Создаю ярлык на рабочем столе...
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $lnk = $ws.CreateShortcut([IO.Path]::Combine($ws.SpecialFolders('Desktop'), 'DeepTutor.lnk')); ^
   $lnk.TargetPath = 'C:\Repos\DeepTutor\start.bat'; ^
   $lnk.WorkingDirectory = 'C:\Repos\DeepTutor'; ^
   $lnk.Description = 'DeepTutor'; ^
   $lnk.WindowStyle = 7; ^
   $lnk.Save(); ^
   Write-Host '        OK'"

echo.
echo  ╔═══════════════════════════════════════════╗
echo  ║                                           ║
echo  ║  Готово! На рабочем столе появился         ║
echo  ║  ярлык «DeepTutor» — нажми два раза.      ║
echo  ║                                           ║
echo  ╚═══════════════════════════════════════════╝
echo.
pause
