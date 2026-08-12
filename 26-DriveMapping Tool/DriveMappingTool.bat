@echo off
REM =======================================================
REM Drive Mapping Tool
REM -------------------------------------------------------
REM This batch file launches the PowerShell version.
REM
REM %~dp0 means:
REM "the directory where this BAT file is located."
REM This allows the script to work even when launched
REM from a different working directory.
REM =======================================================

echo.
echo ===========================================
echo  Drive Mapping Tool
echo ===========================================
echo.

REM Check whether PowerShell 7 (pwsh) is available.
where pwsh >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    pwsh -ExecutionPolicy Bypass -File "%~dp0DriveMappingTool.ps1"
    goto :end
)

REM Fall back to Windows PowerShell if PowerShell 7
REM is not installed.
where powershell >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0DriveMappingTool.ps1"
    goto :end
)

echo PowerShell could not be found.
echo Please install PowerShell and try again.

:end
echo.
pause
