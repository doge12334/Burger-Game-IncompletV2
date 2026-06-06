@echo off
cls

echo =============================
echo Building GameBT...
echo =============================

if not exist output mkdir output

del output\*.obj >nul 2>&1
del GameBT.exe >nul 2>&1

uasm64 -win64 -c -Fooutput\GameBT.obj -I"C:\Users\Filipe\Documents\uasm257_x64\Include" GameBT.asm
if errorlevel 1 goto error

link /SUBSYSTEM:WINDOWS /ENTRY:start /MACHINE:X64 /OUT:BurgerCalamity.exe output\GameBT.obj kernel32.lib user32.lib gdi32.lib
if errorlevel 1 goto error

echo.
echo =============================
echo Build Success
echo =============================

:error
echo.
echo =============================
echo BUILD FAILED
echo =============================
pause

:end