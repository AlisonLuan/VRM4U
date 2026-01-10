@echo off
REM ============================================================================
REM resolve_ue_path.bat
REM
REM Resolves Unreal Engine installation path with the following precedence:
REM   1. Environment variables (UE_ROOT, UE_ENGINE_DIR, UE5BASE, UE4BASE)
REM   2. Local config file (ue_path.config in same directory)
REM   3. Auto-detection (Epic Games Launcher installations)
REM
REM Usage:
REM   call resolve_ue_path.bat <version> [output_var_name]
REM
REM Arguments:
REM   <version>        - UE version (e.g., 5.7, 5.6, 4.27)
REM   [output_var_name] - Optional name for output variable (default: RESOLVED_UE_BASE)
REM
REM Returns:
REM   Sets the specified variable (or RESOLVED_UE_BASE) to the UE base directory
REM   Exit code 0 on success, 1 on failure
REM
REM Examples:
REM   call resolve_ue_path.bat 5.7
REM   echo Found UE at: %RESOLVED_UE_BASE%
REM
REM   call resolve_ue_path.bat 5.6 MY_UE_PATH
REM   echo Found UE at: %MY_UE_PATH%
REM ============================================================================

setlocal enabledelayedexpansion

set REQUESTED_VERSION=%1
set OUTPUT_VAR=%2

REM Default output variable name if not specified
if "%OUTPUT_VAR%"=="" set OUTPUT_VAR=RESOLVED_UE_BASE

if "%REQUESTED_VERSION%"=="" (
    echo [ERROR] UE version not specified
    echo Usage: resolve_ue_path.bat ^<version^> [output_var_name]
    exit /b 1
)

echo [resolve_ue_path] Resolving Unreal Engine %REQUESTED_VERSION% installation path...

REM ============================================================================
REM STEP 1: Check environment variables
REM ============================================================================

REM Check UE_ROOT (highest priority explicit override)
if defined UE_ROOT (
    echo [resolve_ue_path] Found UE_ROOT environment variable: %UE_ROOT%
    set FOUND_PATH=%UE_ROOT%
    goto validate_path
)

REM Check UE_ENGINE_DIR
if defined UE_ENGINE_DIR (
    echo [resolve_ue_path] Found UE_ENGINE_DIR environment variable: %UE_ENGINE_DIR%
    set FOUND_PATH=%UE_ENGINE_DIR%
    goto validate_path
)

REM Check legacy UE5BASE/UE4BASE for backward compatibility
if defined UE5BASE (
    echo [resolve_ue_path] Found UE5BASE environment variable: %UE5BASE%
    set FOUND_PATH=%UE5BASE%
    goto validate_path
)

if defined UE4BASE (
    echo [resolve_ue_path] Found UE4BASE environment variable: %UE4BASE%
    set FOUND_PATH=%UE4BASE%
    goto validate_path
)

REM ============================================================================
REM STEP 2: Check local config file
REM ============================================================================

set CONFIG_FILE=%~dp0ue_path.config
if exist "%CONFIG_FILE%" (
    echo [resolve_ue_path] Found local config file: %CONFIG_FILE%
    for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do (
        set LINE=%%a
        REM Skip empty lines and comments
        if not "!LINE!"=="" (
            set FIRST_CHAR=!LINE:~0,1!
            if not "!FIRST_CHAR!"=="#" (
                echo [resolve_ue_path] Using path from config: %%a
                set FOUND_PATH=%%a
                goto validate_path
            )
        )
    )
)

REM ============================================================================
REM STEP 3: Auto-detection
REM ============================================================================

echo [resolve_ue_path] Attempting auto-detection...

REM Try to detect via Epic Games Launcher metadata
set LAUNCHER_DATA=%ProgramData%\Epic\UnrealEngineLauncher\LauncherInstalled.dat
if exist "%LAUNCHER_DATA%" (
    echo [resolve_ue_path] Found Epic Games Launcher metadata: %LAUNCHER_DATA%
    REM Try to parse JSON using PowerShell
    for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "try { $data = Get-Content '%LAUNCHER_DATA%' -Raw | ConvertFrom-Json; $installs = $data.InstallationList | Where-Object { $_.AppName -like 'UE_*' }; if ($installs) { ($installs | Select-Object -First 1).InstallLocation } } catch { }"`) do (
        set FOUND_PATH=%%i
        if not "!FOUND_PATH!"=="" (
            echo [resolve_ue_path] Detected installation via Launcher metadata
            goto validate_path
        )
    )
)

REM Common installation locations to check
set COMMON_PATHS[0]=C:\Program Files\Epic Games
set COMMON_PATHS[1]=D:\Program Files\Epic Games
set COMMON_PATHS[2]=E:\Program Files\Epic Games
set COMMON_PATHS[3]=C:\Epic Games
set COMMON_PATHS[4]=D:\Epic Games

echo [resolve_ue_path] Scanning common installation locations...
for /L %%i in (0,1,4) do (
    set SCAN_PATH=!COMMON_PATHS[%%i]!
    if exist "!SCAN_PATH!" (
        echo [resolve_ue_path] Checking: !SCAN_PATH!
        REM Check for the specific version first
        set VERSION_PATH=!SCAN_PATH!\UE_%REQUESTED_VERSION%
        if exist "!VERSION_PATH!\Engine\Binaries\Win64\UnrealEditor.exe" (
            set FOUND_PATH=!SCAN_PATH!
            echo [resolve_ue_path] Found matching version at: !FOUND_PATH!
            goto validate_path
        )
        if exist "!VERSION_PATH!\Engine\Build\BatchFiles\RunUAT.bat" (
            set FOUND_PATH=!SCAN_PATH!
            echo [resolve_ue_path] Found matching version at: !FOUND_PATH!
            goto validate_path
        )
        REM If specific version not found, check if any UE installation exists
        for /d %%d in ("!SCAN_PATH!\UE_*") do (
            if exist "%%d\Engine\Binaries\Win64\UnrealEditor.exe" (
                set FOUND_PATH=!SCAN_PATH!
                echo [resolve_ue_path] Found UE installation at: !FOUND_PATH!
                goto validate_path
            )
            if exist "%%d\Engine\Build\BatchFiles\RunUAT.bat" (
                set FOUND_PATH=!SCAN_PATH!
                echo [resolve_ue_path] Found UE installation at: !FOUND_PATH!
                goto validate_path
            )
        )
    )
)

REM If we get here, nothing was found
goto not_found

REM ============================================================================
REM Path validation
REM ============================================================================

:validate_path
echo [resolve_ue_path] Validating path: %FOUND_PATH%

REM Build the full version path
set UE_VERSION_PATH=%FOUND_PATH%\UE_%REQUESTED_VERSION%

REM Check if the version-specific directory exists
if not exist "%UE_VERSION_PATH%" (
    echo [ERROR] Version directory not found: %UE_VERSION_PATH%
    echo [ERROR] The base path exists but UE_%REQUESTED_VERSION% was not found.
    goto validation_failed
)

REM Check for required files
set RUNUAT=%UE_VERSION_PATH%\Engine\Build\BatchFiles\RunUAT.bat
set UNREAL_EDITOR=%UE_VERSION_PATH%\Engine\Binaries\Win64\UnrealEditor.exe
set UNREAL_EDITOR_CMD=%UE_VERSION_PATH%\Engine\Binaries\Win64\UnrealEditor-Cmd.exe

set VALIDATION_OK=0

if exist "%RUNUAT%" (
    echo [resolve_ue_path] Found RunUAT.bat
    set VALIDATION_OK=1
) else (
    echo [WARNING] RunUAT.bat not found at: %RUNUAT%
)

if exist "%UNREAL_EDITOR%" (
    echo [resolve_ue_path] Found UnrealEditor.exe
    set VALIDATION_OK=1
) else if exist "%UNREAL_EDITOR_CMD%" (
    echo [resolve_ue_path] Found UnrealEditor-Cmd.exe
    set VALIDATION_OK=1
) else (
    echo [WARNING] UnrealEditor not found at expected location
)

if %VALIDATION_OK%==0 (
    echo [ERROR] Path validation failed - required UE files not found
    goto validation_failed
)

echo [resolve_ue_path] ========================================
echo [resolve_ue_path] SUCCESS: Unreal Engine %REQUESTED_VERSION% found
echo [resolve_ue_path] Base path: %FOUND_PATH%
echo [resolve_ue_path] Full path: %UE_VERSION_PATH%
echo [resolve_ue_path] ========================================

REM Return the value to the caller
endlocal & set %OUTPUT_VAR%=%FOUND_PATH%
exit /b 0

REM ============================================================================
REM Error handling
REM ============================================================================

:validation_failed
echo.
echo [ERROR] ========================================
echo [ERROR] Path validation failed for: %FOUND_PATH%
echo [ERROR] ========================================
goto show_help

:not_found
echo.
echo [ERROR] ========================================
echo [ERROR] Unreal Engine %REQUESTED_VERSION% not found
echo [ERROR] ========================================
echo.
echo [resolve_ue_path] Attempted:
echo   1. Environment variables: UE_ROOT, UE_ENGINE_DIR, UE5BASE, UE4BASE
echo   2. Local config file: %CONFIG_FILE%
echo   3. Auto-detection in common paths:
for /L %%i in (0,1,4) do (
    echo      - !COMMON_PATHS[%%i]!
)
echo   4. Epic Games Launcher metadata: %LAUNCHER_DATA%
echo.

:show_help
echo [resolve_ue_path] How to fix:
echo.
echo   Option 1: Set environment variable (recommended for CI/automation)
echo     set UE_ROOT=C:\Path\To\Epic Games
echo     OR
echo     set UE5BASE=C:\Path\To\Epic Games
echo.
echo   Option 2: Create local config file (recommended for local development)
echo     Create file: %~dp0ue_path.config
echo     Add one line with your UE base path, for example:
echo       C:\Program Files\Epic Games
echo.
echo   Option 3: Ensure Epic Games Launcher is installed and has installed UE %REQUESTED_VERSION%
echo     The expected directory structure:
echo       ^<base_path^>\UE_%REQUESTED_VERSION%\Engine\Build\BatchFiles\RunUAT.bat
echo       ^<base_path^>\UE_%REQUESTED_VERSION%\Engine\Binaries\Win64\UnrealEditor.exe
echo.
endlocal
exit /b 1
