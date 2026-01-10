@echo off
REM ============================================================================
REM Make script location-independent: always run relative to script directory
REM ============================================================================
cd /d %~dp0

REM ============================================================================
REM build_all.bat - Complete multi-version build script
REM
REM This script builds VRM4U for all configured UE versions (UE5 and legacy).
REM It orchestrates:
REM   1. build_5.bat - All UE5 versions
REM   2. build_old.bat - Legacy UE4 versions (if applicable)
REM
REM Usage:
REM   build_all.bat
REM
REM Recommended invocation for full logging:
REM   cmd /c build_all.bat > full_build_log.txt 2>&1
REM
REM Note: This captures all output (stdout and stderr) to a file for debugging.
REM       If a build fails, check the log file for detailed error messages.
REM ============================================================================

call build_5.bat
if not %errorlevel% == 0 (
    echo [ERROR] :P
    goto err
)
call build_old.bat
if not %errorlevel% == 0 (
    echo [ERROR] :P
    goto err
)


:finish
exit /b 0

:err
exit /b 1


