@echo off
setlocal
cd /d "%~dp0"

echo.
echo === Building StickyNotesViewer (release) ===
call flutter build windows --release
if errorlevel 1 (
    echo.
    echo Build failed.
    pause
    exit /b 1
)

set "TARGET=F:\Soft\StickyNotesViewer"
if not exist "%TARGET%" mkdir "%TARGET%"

echo.
echo === Copying to %TARGET% ===
robocopy "build\windows\x64\runner\Release" "%TARGET%" /MIR /NFL /NDL /NJH /NP
if errorlevel 8 (
    echo.
    echo Copy failed.
    pause
    exit /b 1
)

echo.
echo Done. Release is in %TARGET%
endlocal
