@echo off
REM ============================================================================
REM build_5.bat - Multi-version UE5 plugin build script with resilient handling
REM
REM This script builds VRM4U for multiple UE5 versions with configurable
REM version list and skip-on-missing behavior.
REM
REM Configuration:
REM   1. Environment variable BUILD_UE_VERSIONS (e.g., "5.7,5.6,5.5")
REM   2. versions.txt file (one version per line)
REM   3. Default hard-coded list if neither above is set
REM
REM Behavior:
REM   - By default, skips missing versions with a warning
REM   - Set STRICT_VERSIONS=1 to fail if any version is missing
REM
REM ============================================================================

setlocal enabledelayedexpansion

set V_DATE=%date:~0,4%%date:~5,2%%date:~8,2%
set BUILD_SCRIPT=build_ver2.bat

REM ============================================================================
REM Load version list from configuration
REM ============================================================================

set "VERSION_LIST="
set "VERSION_SOURCE=default"

REM Priority 1: BUILD_UE_VERSIONS environment variable
if defined BUILD_UE_VERSIONS (
    set "VERSION_LIST=%BUILD_UE_VERSIONS%"
    set "VERSION_SOURCE=BUILD_UE_VERSIONS environment variable"
    echo [build_5] Using BUILD_UE_VERSIONS environment variable
)

REM Priority 2: versions.txt file
if not defined VERSION_LIST (
    set VERSIONS_FILE=%~dp0versions.txt
    if exist "!VERSIONS_FILE!" (
        echo [build_5] Found versions.txt file
        set "VERSION_SOURCE=versions.txt"
        set "VERSION_LIST="
        for /f "usebackq tokens=*" %%a in ("!VERSIONS_FILE!") do (
            set LINE=%%a
            REM Skip empty lines and comments
            if not "!LINE!"=="" (
                set FIRST_CHAR=!LINE:~0,1!
                if not "!FIRST_CHAR!"=="#" (
                    REM Trim leading/trailing spaces
                    for /f "tokens=* delims= " %%b in ("!LINE!") do set TRIMMED=%%b
                    if not "!TRIMMED!"=="" (
                        if defined VERSION_LIST (
                            set "VERSION_LIST=!VERSION_LIST!,!TRIMMED!"
                        ) else (
                            set "VERSION_LIST=!TRIMMED!"
                        )
                    )
                )
            )
        )
    )
)

REM Priority 3: Default hard-coded list
if not defined VERSION_LIST (
    set "VERSION_LIST=5.7,5.6,5.5,5.4,5.3,5.2"
    set "VERSION_SOURCE=default hard-coded list"
    echo [build_5] Using default version list
)

echo [build_5] ========================================
echo [build_5] Multi-Version Build Configuration
echo [build_5] ========================================
echo [build_5] Version source: %VERSION_SOURCE%
echo [build_5] Versions to build: %VERSION_LIST%
echo [build_5] Strict mode: %STRICT_VERSIONS% (1=fail on missing, empty=skip on missing)
echo [build_5] ========================================
echo.

REM ============================================================================
REM Track build results
REM ============================================================================

set BUILD_COUNT=0
set SKIP_COUNT=0
set "BUILT_VERSIONS="
set "SKIPPED_VERSIONS="

REM ============================================================================
REM Process each version
REM ============================================================================

REM Sanitize VERSION_LIST to prevent command injection
REM Remove potentially dangerous metacharacters before iteration
set "SAFE_VERSION_LIST=%VERSION_LIST%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:&=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:|=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:>=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:<=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:(=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:)=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:^=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:%%=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:;=%"
set "SAFE_VERSION_LIST=%SAFE_VERSION_LIST:`=%"

for %%V in (%SAFE_VERSION_LIST%) do (
    set CURRENT_VERSION=%%V
    echo.
    echo [build_5] ========================================
    echo [build_5] Processing UE !CURRENT_VERSION!
    echo [build_5] ========================================
    
    REM Check if this version is installed
    call "%~dp0resolve_ue_path.bat" !CURRENT_VERSION! >nul 2>nul
    set RESOLVE_EXIT_CODE=!errorlevel!
    
    if !RESOLVE_EXIT_CODE! == 0 (
        echo [build_5] UE !CURRENT_VERSION! found - proceeding with builds
        call :build_version !CURRENT_VERSION!
        if !errorlevel! == 0 (
            set /a BUILD_COUNT+=1
            if defined BUILT_VERSIONS (
                set "BUILT_VERSIONS=!BUILT_VERSIONS!, !CURRENT_VERSION!"
            ) else (
                set "BUILT_VERSIONS=!CURRENT_VERSION!"
            )
        ) else (
            echo [build_5] [ERROR] Build failed for UE !CURRENT_VERSION!
            goto err
        )
    ) else (
        REM Version not installed
        echo.
        echo [build_5] ========================================
        echo [build_5] WARNING: UE !CURRENT_VERSION! not installed
        echo [build_5] ========================================
        
        REM Run resolve_ue_path again to show detailed error message
        call "%~dp0resolve_ue_path.bat" !CURRENT_VERSION! 2>nul
        
        echo.
        echo [build_5] How to fix:
        echo [build_5]   Option 1: Install UE !CURRENT_VERSION! via Epic Games Launcher
        echo [build_5]   Option 2: Remove !CURRENT_VERSION! from your version list:
        
        if "%VERSION_SOURCE%"=="BUILD_UE_VERSIONS environment variable" (
            echo [build_5]            - Update BUILD_UE_VERSIONS environment variable
        ) else if "%VERSION_SOURCE%"=="versions.txt" (
            echo [build_5]            - Edit %~dp0versions.txt
        ) else (
            echo [build_5]            - Create %~dp0versions.txt with only your installed versions
        )
        
        echo [build_5]   Option 3: Set environment variable to specify UE path:
        echo [build_5]            - set UE_ROOT=C:\Path\To\Epic Games
        echo.
        
        if "%STRICT_VERSIONS%"=="1" (
            echo [build_5] [ERROR] STRICT_VERSIONS=1 - Failing build due to missing version
            goto err
        ) else (
            echo [build_5] Skipping UE !CURRENT_VERSION! and continuing...
            set /a SKIP_COUNT+=1
            if defined SKIPPED_VERSIONS (
                set "SKIPPED_VERSIONS=!SKIPPED_VERSIONS!, !CURRENT_VERSION!"
            ) else (
                set "SKIPPED_VERSIONS=!CURRENT_VERSION!"
            )
        )
    )
)

REM ============================================================================
REM Build summary
REM ============================================================================

echo.
echo [build_5] ========================================
echo [build_5] Build Summary
echo [build_5] ========================================
echo [build_5] Versions built: !BUILD_COUNT!
if defined BUILT_VERSIONS (
    echo [build_5]   ^> !BUILT_VERSIONS!
)
echo [build_5] Versions skipped: !SKIP_COUNT!
if defined SKIPPED_VERSIONS (
    echo [build_5]   ^> !SKIPPED_VERSIONS!
)
echo [build_5] ========================================

if !BUILD_COUNT! == 0 (
    echo [build_5] [ERROR] No versions were successfully built!
    goto err
)

echo [build_5] SUCCESS - Build completed
endlocal
exit /b 0

REM ============================================================================
REM Subroutine: Build a specific version with all its platform configurations
REM ============================================================================
:build_version
setlocal
set VERSION=%1

REM Define platform configurations for each version
REM Format: Platform Configuration ZipNameSuffix

if "%VERSION%"=="5.7" (
    call :build_platform %VERSION% Win64 Shipping ""
    if !errorlevel! neq 0 exit /b 1
    call :build_platform %VERSION% Android Development "_android"
    if !errorlevel! neq 0 exit /b 1
    call :build_platform %VERSION% Linux Shipping "_linux"
    if !errorlevel! neq 0 exit /b 1
) else if "%VERSION%"=="5.6" (
    call :build_platform %VERSION% Win64 Shipping ""
    if !errorlevel! neq 0 exit /b 1
    call :build_platform %VERSION% Android Development "_android"
    if !errorlevel! neq 0 exit /b 1
) else if "%VERSION%"=="5.5" (
    call :build_platform %VERSION% Win64 Shipping ""
    if !errorlevel! neq 0 exit /b 1
    call :build_platform %VERSION% Win64 Debug "_debug"
    if !errorlevel! neq 0 exit /b 1
) else (
    REM Default: Win64 Shipping only
    call :build_platform %VERSION% Win64 Shipping ""
    if !errorlevel! neq 0 exit /b 1
)

endlocal
exit /b 0

REM ============================================================================
REM Subroutine: Build a specific platform configuration
REM ============================================================================
:build_platform
setlocal
set BLD_VERSION=%1
set BLD_PLATFORM=%2
set BLD_CONFIG=%3
set BLD_SUFFIX=%4

REM Convert version with dots to underscores for filename
set BLD_VERSION_FILE=%BLD_VERSION:.=_%

set ZIPNAME=VRM4U_%BLD_VERSION_FILE%_%V_DATE%%BLD_SUFFIX%.zip

echo [build_5] Building: UE %BLD_VERSION% / %BLD_PLATFORM% / %BLD_CONFIG% -^> %ZIPNAME%

call %BUILD_SCRIPT% %BLD_VERSION% %BLD_PLATFORM% %BLD_CONFIG% %ZIPNAME%
if not !errorlevel! == 0 (
    echo [build_5] [ERROR] Build failed for UE %BLD_VERSION% %BLD_PLATFORM% %BLD_CONFIG%
    endlocal
    exit /b 1
)

echo [build_5] Successfully built: %ZIPNAME%
endlocal
exit /b 0

REM ============================================================================
REM Error handler
REM ============================================================================
:err
echo.
echo [build_5] ========================================
echo [build_5] Build process failed
echo [build_5] ========================================
endlocal
exit /b 1

