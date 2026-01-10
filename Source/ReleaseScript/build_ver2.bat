
set UE5VER=%1
set PLATFORM=%2
set BUILDTYPE=%3
set ZIPNAME=../../../../_zip/%4

REM Resolve Unreal Engine installation path
REM This replaces the hard-coded path with auto-detection + override support
call "%~dp0resolve_ue_path.bat" %UE5VER% UE5BASE
if not %errorlevel% == 0 (
    echo [ERROR] Failed to resolve Unreal Engine %UE5VER% path
    echo [ERROR] See error messages above for details
    goto err
)

set UPLUGIN="%~dp0../../VRM4U.uplugin"

REM ============================================================================
REM Configure output path with override support
REM ============================================================================
REM Precedence:
REM   1. VRM4U_OUTPATH environment variable (highest priority)
REM   2. OUTPATH environment variable
REM   3. Default: %TEMP%\VRM4U_BuildOut (safe fallback)
REM ============================================================================

setlocal enabledelayedexpansion

if defined VRM4U_OUTPATH (
    set "RESOLVED_OUTPATH=%VRM4U_OUTPATH%"
    echo [build_ver2] Using VRM4U_OUTPATH environment variable: !RESOLVED_OUTPATH!
) else if defined OUTPATH (
    set "RESOLVED_OUTPATH=%OUTPATH%"
    echo [build_ver2] Using OUTPATH environment variable: !RESOLVED_OUTPATH!
) else (
    REM Use TEMP directory as safe default
    set "RESOLVED_OUTPATH=%TEMP%\VRM4U_BuildOut"
    echo [build_ver2] Using default output path: !RESOLVED_OUTPATH!
)

REM Normalize path separators (convert forward slashes to backslashes for Windows)
set "RESOLVED_OUTPATH=!RESOLVED_OUTPATH:/=\!"

echo [build_ver2] Output directory: !RESOLVED_OUTPATH!

REM Create the output directory if it doesn't exist
if not exist "!RESOLVED_OUTPATH!" (
    echo [build_ver2] Creating output directory...
    mkdir "!RESOLVED_OUTPATH!" 2>nul
    if not exist "!RESOLVED_OUTPATH!" (
        echo [ERROR] ========================================
        echo [ERROR] Failed to create output directory: !RESOLVED_OUTPATH!
        echo [ERROR] ========================================
        echo.
        echo [ERROR] This may be because:
        echo   - The path is invalid
        echo   - You lack permissions to create the directory
        echo   - The parent directory does not exist
        echo.
        echo [ERROR] To fix, set VRM4U_OUTPATH to a writable location:
        echo   set VRM4U_OUTPATH=C:\BuildOutput
        echo   OR
        echo   set VRM4U_OUTPATH=%%CD%%\_out
        echo.
        endlocal
        goto err
    )
)

REM Validate write access by creating a test file
echo Testing write access... > "!RESOLVED_OUTPATH!\test_write_access.tmp" 2>nul
if not exist "!RESOLVED_OUTPATH!\test_write_access.tmp" (
    echo [ERROR] ========================================
    echo [ERROR] Output directory is not writable: !RESOLVED_OUTPATH!
    echo [ERROR] ========================================
    echo.
    echo [ERROR] To fix, set VRM4U_OUTPATH to a writable location:
    echo   set VRM4U_OUTPATH=C:\BuildOutput
    echo   OR
    echo   set VRM4U_OUTPATH=%%CD%%\_out
    echo.
    endlocal
    goto err
)
del "!RESOLVED_OUTPATH!\test_write_access.tmp" 2>nul

echo [build_ver2] Output directory validated successfully
echo.

REM Convert to forward slashes for UAT (it expects Unix-style paths)
set "OUTPATH_FOR_UAT=!RESOLVED_OUTPATH:\=/!"

REM Export for use in the rest of the script
endlocal & set "OUTPATH=%OUTPATH_FOR_UAT%"

git reset --hard HEAD

powershell -ExecutionPolicy RemoteSigned .\version.ps1 \"%UE5VER%\"

set UE5PATH=UE_%UE5VER%

set BUILD="%UE5BASE%\%UE5PATH%\Engine\Build\BatchFiles\RunUAT.bat"

::: delete

REM Parse version components (supports decimal versions like 5.7)
for /f "tokens=1,2 delims=." %%a in ("%UE5VER%") do (
    set UEMajorVersion=%%a
    set UEMinorVersion=%%b
)

REM Try to use WSL + bc for version math (multiply by 100, e.g., 5.7 -> 570)
set "UEVersion100="
for /f %%i in ('wsl echo "%UE5VER% * 100" 2^>nul ^| bc 2^>nul') do set UEVersion100=%%i

REM Fallback if WSL or bc are not available: compute UEVersion100 using batch math
if not defined UEVersion100 (
    REM Default minor version to 0 if not present
    if not defined UEMinorVersion set UEMinorVersion=0
    set /a UEVersion100=UEMajorVersion*100+UEMinorVersion
)

REM Also keep an integer major version (e.g., 5 from 5.7) for any simple comparisons
set /a UEVersion=UEMajorVersion 2>nul

REM Delete optional editor widget assets (suppress errors if files don't exist)
del "..\..\..\VRM4U\Content\Util\Actor\latest\WBP_MorphTarget.uasset" 2>nul
del "..\..\..\VRM4U\Content\Util\Actor\latest\WBP_MorphTargetUE5.uasset" 2>nul

set isRetargeterEnable=TRUE

if %UE5VER% == 5.0 set isRetargeterEnable=FALSE
if %UE5VER% == 5.1 set isRetargeterEnable=FALSE

if %isRetargeterEnable% == FALSE (
del "..\..\..\VRM4U\Source\VRM4U\Private\VrmAnimInstanceRetargetFromMannequin.cpp"
del "..\..\..\VRM4U\Source\VRM4U\Public\VrmAnimInstanceRetargetFromMannequin.h"
)

set isRenderModuleEnable=TRUE
if %UE5VER% == 5.0 set isRenderModuleEnable=FALSE

if %isRenderModuleEnable% == FALSE (
del "..\..\..\VRM4U\Source\VRM4URender\VRM4URender.Build.cs"
)


::::::::::::::::::::::::::: generate


call %BUILD% BuildPlugin -plugin=%UPLUGIN% -package=%OUTPATH% -TargetPlatforms=%PLATFORM% -clientconfig=%BUILDTYPE% %UPROJECT%

if not %errorlevel% == 0 (
    echo [ERROR] :P
    goto err
)


powershell -ExecutionPolicy RemoteSigned .\compress2.ps1 %ZIPNAME% %OUTPATH%



:finish
exit /b 0

:err
exit /b 1


