@echo off
chcp 65001 >nul
title Pack DeepTutor
cd /d "%~dp0"

echo.
echo  Podgotovka DeepTutor dlya perenosa
echo  ===================================
echo.
set /p DRIVE="  Drive letter (e.g. D): "
set "USB=%DRIVE%:\"

if not exist "%USB%" (
    echo  Drive %USB% not found!
    pause
    exit /b 1
)

echo.
echo  Copying project to %USB%DeepTutor ...
echo  (shows each file with percent and ETA; large files may sit on one line)
echo.
robocopy "%~dp0." "%USB%DeepTutor" /mir /njh /njs /ndl /eta ^
    /xd node_modules .venv .next .git __pycache__ .mypy_cache .ruff_cache ^
    /xf *.pyc pack.bat
set RC=%ERRORLEVEL%
:: robocopy exit codes: 0-7 = success (files copied / nothing to do / minor),
:: 8+ = failure. Normalize to 0 unless real error.
if %RC% GEQ 8 (
    echo.
    echo  ERROR: robocopy failed with code %RC%
    pause
    exit /b %RC%
)

echo.
echo  Copying installer to USB root...
copy /y "%~dp0setup_daughter.bat" "%USB%setup.bat" >nul

echo.
echo  Done! USB %USB% contains:
echo    setup.bat    — run on daughter's laptop
echo    DeepTutor\   — project folder
echo.
pause
