#Requires -Version 5.0
<#
.SYNOPSIS
    Robust compression script for VRM4U plugin packaging

.DESCRIPTION
    This script packages the VRM4U plugin into a zip file with proper error handling.
    
    It performs the following steps:
    1. Validates input paths
    2. Cleans up intermediate build artifacts
    3. Copies ThirdParty dependencies
    4. Creates plugin directory structure
    5. Compresses to zip file
    6. Cleans up temporary files

.PARAMETER ZipDestination
    Full path to the output zip file (e.g., "C:\Output\_zip\VRM4U_5_7_20260110.zip")

.PARAMETER BuildOutput
    Path to the UAT BuildPlugin output directory (e.g., "C:\Temp\VRM4U_BuildOut")

.EXAMPLE
    .\compress2.ps1 "C:\Output\_zip\VRM4U_5_7.zip" "C:\Temp\VRM4U_BuildOut"
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ZipDestination,
    
    [Parameter(Mandatory=$true, Position=1)]
    [string]$BuildOutput
)

$ErrorActionPreference = 'Stop'

function Write-CompressLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        "ERROR" { "[$timestamp] [compress2] [ERROR]" }
        "WARNING" { "[$timestamp] [compress2] [WARNING]" }
        default { "[$timestamp] [compress2]" }
    }
    Write-Host "$prefix $Message"
}

try {
    Write-CompressLog "=========================================="
    Write-CompressLog "VRM4U Plugin Compression Script"
    Write-CompressLog "=========================================="
    Write-CompressLog "Zip destination: $ZipDestination"
    Write-CompressLog "Build output: $BuildOutput"
    Write-CompressLog ""

    # ============================================================================
    # Validate inputs
    # ============================================================================
    
    Write-CompressLog "Validating input paths..."
    
    if ([string]::IsNullOrWhiteSpace($ZipDestination)) {
        throw "Zip destination path is empty or null"
    }
    
    if ([string]::IsNullOrWhiteSpace($BuildOutput)) {
        throw "Build output path is empty or null"
    }
    
    # Normalize paths (convert forward slashes to backslashes on Windows)
    $BuildOutput = $BuildOutput -replace '/', '\'
    $ZipDestination = $ZipDestination -replace '/', '\'
    
    Write-CompressLog "Normalized build output: $BuildOutput"
    Write-CompressLog "Normalized zip destination: $ZipDestination"
    
    # Check if build output directory exists
    if (-not (Test-Path -Path $BuildOutput -PathType Container)) {
        throw "Build output directory does not exist: $BuildOutput"
    }
    
    Write-CompressLog "Build output directory validated"
    
    # ============================================================================
    # Ensure zip destination directory exists
    # ============================================================================
    
    $zipDestDir = Split-Path -Parent $ZipDestination
    if (-not [string]::IsNullOrWhiteSpace($zipDestDir)) {
        if (-not (Test-Path -Path $zipDestDir)) {
            Write-CompressLog "Creating zip destination directory: $zipDestDir"
            New-Item -ItemType Directory -Path $zipDestDir -Force -ErrorAction Stop | Out-Null
            Write-CompressLog "Destination directory created successfully"
        } else {
            Write-CompressLog "Destination directory already exists"
        }
    }
    
    # ============================================================================
    # Clean up intermediate artifacts from build output
    # ============================================================================
    
    Write-CompressLog ""
    Write-CompressLog "Cleaning up build artifacts..."
    
    $intermediateDir = Join-Path $BuildOutput "Intermediate"
    if (Test-Path -Path $intermediateDir) {
        Write-CompressLog "Removing Intermediate directory..."
        Remove-Item -Recurse -Force $intermediateDir -ErrorAction SilentlyContinue
    }
    
    $pdbPattern = Join-Path $BuildOutput "Binaries\Win64\*.pdb"
    if (Test-Path -Path $pdbPattern) {
        Write-CompressLog "Removing PDB files..."
        Remove-Item -Force $pdbPattern -ErrorAction SilentlyContinue
    }
    
    $releaseScriptDir = Join-Path $BuildOutput "Source\ReleaseScript"
    if (Test-Path -Path $releaseScriptDir) {
        Write-CompressLog "Removing ReleaseScript directory..."
        Remove-Item -Recurse -Force $releaseScriptDir -ErrorAction SilentlyContinue
    }
    
    Write-CompressLog "Cleanup complete"
    
    # ============================================================================
    # Copy ThirdParty dependencies
    # ============================================================================
    
    Write-CompressLog ""
    Write-CompressLog "Copying ThirdParty dependencies..."
    
    $thirdPartySource = Join-Path $PSScriptRoot "..\..\ThirdParty"
    $thirdPartyDest = Join-Path $BuildOutput "ThirdParty"
    
    if (Test-Path -Path $thirdPartySource) {
        Copy-Item -Path $thirdPartySource -Destination $thirdPartyDest -Recurse -Container -Force -ErrorAction Stop
        Write-CompressLog "ThirdParty dependencies copied successfully"
    } else {
        Write-CompressLog "ThirdParty source not found: $thirdPartySource" "WARNING"
        Write-CompressLog "Continuing without ThirdParty dependencies" "WARNING"
    }
    
    # ============================================================================
    # Create plugin directory structure
    # ============================================================================
    
    Write-CompressLog ""
    Write-CompressLog "Creating plugin directory structure..."
    
    $pluginsDir = Join-Path $PSScriptRoot "Plugins"
    if (Test-Path -Path $pluginsDir) {
        Write-CompressLog "Removing existing Plugins directory..."
        Remove-Item -Recurse -Force $pluginsDir -ErrorAction SilentlyContinue
    }
    
    New-Item -ItemType Directory -Path $pluginsDir -Force -ErrorAction Stop | Out-Null
    Write-CompressLog "Created Plugins directory"
    
    $pluginVrm4uDir = Join-Path $pluginsDir "VRM4U"
    Write-CompressLog "Moving build output to Plugins/VRM4U..."
    Move-Item -Path $BuildOutput -Destination $pluginVrm4uDir -Force -ErrorAction Stop
    Write-CompressLog "Plugin structure created successfully"
    
    # ============================================================================
    # Compress to zip file
    # ============================================================================
    
    Write-CompressLog ""
    Write-CompressLog "Compressing plugin to zip file..."
    Write-CompressLog "This may take a minute..."
    
    # Change to the script directory to ensure relative paths work correctly
    Push-Location $PSScriptRoot
    
    try {
        Compress-Archive -Force -Path $pluginsDir -DestinationPath $ZipDestination -ErrorAction Stop
        Write-CompressLog ""
        Write-CompressLog "=========================================="
        Write-CompressLog "SUCCESS: Plugin packaged successfully"
        Write-CompressLog "Output: $ZipDestination"
        Write-CompressLog "=========================================="
    }
    finally {
        Pop-Location
    }
    
    # ============================================================================
    # Cleanup temporary directories
    # ============================================================================
    
    Write-CompressLog ""
    Write-CompressLog "Cleaning up temporary directories..."
    
    if (Test-Path -Path $pluginsDir) {
        Remove-Item -Recurse -Force $pluginsDir -ErrorAction SilentlyContinue
        Write-CompressLog "Removed Plugins directory"
    }
    
    # Note: BuildOutput was already moved into Plugins/VRM4U, so it's cleaned up with Plugins
    
    Write-CompressLog "Cleanup complete"
    Write-CompressLog ""
    
    exit 0
}
catch {
    Write-CompressLog "" "ERROR"
    Write-CompressLog "==========================================" "ERROR"
    Write-CompressLog "COMPRESSION FAILED" "ERROR"
    Write-CompressLog "==========================================" "ERROR"
    Write-CompressLog "Error: $($_.Exception.Message)" "ERROR"
    Write-CompressLog "" "ERROR"
    Write-CompressLog "Troubleshooting:" "ERROR"
    Write-CompressLog "  1. Check that the build output directory exists and contains valid plugin files" "ERROR"
    Write-CompressLog "  2. Verify that the destination directory is writable" "ERROR"
    Write-CompressLog "  3. Ensure you have sufficient disk space" "ERROR"
    Write-CompressLog "  4. Check that no other process is locking the files" "ERROR"
    Write-CompressLog "" "ERROR"
    Write-CompressLog "Build output: $BuildOutput" "ERROR"
    Write-CompressLog "Zip destination: $ZipDestination" "ERROR"
    Write-CompressLog "" "ERROR"
    
    # Attempt cleanup on error (best effort, don't throw)
    if (Test-Path -Path $pluginsDir -ErrorAction SilentlyContinue) {
        Write-CompressLog "Attempting to clean up temporary Plugins directory..." "ERROR"
        Remove-Item -Recurse -Force $pluginsDir -ErrorAction SilentlyContinue
    }
    
    exit 1
}
