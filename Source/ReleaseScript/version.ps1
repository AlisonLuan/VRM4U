# ============================================================================
# version.ps1 - Update EngineAssociation and modify VRM4U.uplugin per version
# ============================================================================
# Usage:
#   version.ps1 <EngineVersion> [TargetFilePath]
#
# Arguments:
#   EngineVersion    - The UE version (e.g., "5.7", "4.27")
#   TargetFilePath   - Optional: Path to .uplugin or .uproject file to modify
#                      If not provided, operates in plugin-only mode
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$EngineVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$TargetFilePath = ""
)

Write-Host "[version.ps1] Starting - EngineVersion: $EngineVersion"
if ($TargetFilePath) {
    Write-Host "[version.ps1] Target file: $TargetFilePath"
} else {
    Write-Host "[version.ps1] No target file specified - plugin-only mode"
}

# ============================================================================
# Helper function: Read and parse JSON file safely
# ============================================================================
function Read-JsonFileSafe {
    param(
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "[version.ps1] ERROR: File not found: $FilePath"
        return $null
    }
    
    try {
        # Read file content with UTF8 encoding, handling BOM
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
        
        # Parse JSON
        $jsonObject = $content | ConvertFrom-Json -ErrorAction Stop
        
        if ($null -eq $jsonObject) {
            Write-Host "[version.ps1] ERROR: Parsed JSON is null for: $FilePath"
            return $null
        }
        
        return $jsonObject
        
    } catch {
        Write-Host "[version.ps1] ERROR: Failed to read/parse JSON file: $FilePath"
        Write-Host "[version.ps1] Error details: $_"
        Write-Host "[version.ps1] File excerpt (first 200 chars):"
        try {
            $excerpt = (Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue).Substring(0, [Math]::Min(200, $content.Length))
            Write-Host $excerpt
        } catch {
            Write-Host "(Could not read file excerpt)"
        }
        return $null
    }
}

# ============================================================================
# Helper function: Write JSON file safely with proper formatting
# ============================================================================
function Write-JsonFileSafe {
    param(
        [object]$JsonObject,
        [string]$FilePath
    )
    
    try {
        # Convert to JSON with proper depth to avoid truncation
        $jsonContent = $JsonObject | ConvertTo-Json -Depth 10 -ErrorAction Stop
        
        # Write with UTF8 encoding (no BOM)
        [System.IO.File]::WriteAllText($FilePath, $jsonContent, [System.Text.UTF8Encoding]::new($false))
        
        Write-Host "[version.ps1] Successfully wrote: $FilePath"
        return $true
        
    } catch {
        Write-Host "[version.ps1] ERROR: Failed to write JSON file: $FilePath"
        Write-Host "[version.ps1] Error details: $_"
        return $false
    }
}

# ============================================================================
# Step 1: Update EngineAssociation in target file (if provided)
# ============================================================================
$targetFileObj = $null
if ($TargetFilePath -and $TargetFilePath -ne "") {
    Write-Host "[version.ps1] Reading target file for EngineAssociation update..."
    $targetFileObj = Read-JsonFileSafe -FilePath $TargetFilePath
    
    if ($null -eq $targetFileObj) {
        Write-Host "[version.ps1] ERROR: Failed to read target file, cannot update EngineAssociation"
        exit 1
    }
    
    # Ensure EngineAssociation property exists
    if (-not (Get-Member -InputObject $targetFileObj -Name "EngineAssociation" -MemberType Properties)) {
        Write-Host "[version.ps1] EngineAssociation property not found - adding it"
        $targetFileObj | Add-Member -MemberType NoteProperty -Name "EngineAssociation" -Value ""
    }
    
    # Update the EngineAssociation
    $targetFileObj.EngineAssociation = $EngineVersion
    Write-Host "[version.ps1] Updated EngineAssociation to: $EngineVersion"
    
    # Write back to file
    if (-not (Write-JsonFileSafe -JsonObject $targetFileObj -FilePath $TargetFilePath)) {
        Write-Host "[version.ps1] ERROR: Failed to write updated target file"
        exit 1
    }
}

# Store the engine association for later use
$a = [PSCustomObject]@{
    EngineAssociation = $EngineVersion
}

# ============================================================================
# Step 2: Modify VRM4U.uplugin based on engine version
# ============================================================================
# Determine the absolute path to VRM4U.uplugin
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$upluginPath = Join-Path $scriptDir "..\..\VRM4U.uplugin" | Resolve-Path

Write-Host "[version.ps1] VRM4U.uplugin path: $upluginPath"

# Read the .uplugin file
$upluginObj = Read-JsonFileSafe -FilePath $upluginPath
if ($null -eq $upluginObj) {
    Write-Host "[version.ps1] ERROR: Failed to read VRM4U.uplugin"
    exit 1
}

$modified = $false

# For UE 4.20-4.23: Change module type to 'Developer'
if ($EngineVersion -eq '4.23' -or $EngineVersion -eq '4.22' -or $EngineVersion -eq '4.21' -or $EngineVersion -eq '4.20') {
    Write-Host "[version.ps1] UE $EngineVersion detected - setting Modules[5].Type to 'Developer'"
    if ($upluginObj.Modules.Count -gt 5) {
        $upluginObj.Modules[5].Type = 'Developer'
        $modified = $true
    } else {
        Write-Host "[version.ps1] WARNING: Expected at least 6 modules but found $($upluginObj.Modules.Count)"
    }
}

# For UE 4.20-4.27: Remove plugin dependencies (indices 3, 2, 1)
if ($EngineVersion -eq '4.27' -or $EngineVersion -eq '4.26' -or $EngineVersion -eq '4.25' -or $EngineVersion -eq '4.24' -or 
    $EngineVersion -eq '4.23' -or $EngineVersion -eq '4.22' -or $EngineVersion -eq '4.21' -or $EngineVersion -eq '4.20') {
    
    Write-Host "[version.ps1] UE $EngineVersion detected - removing plugin dependencies at indices 3, 2, 1"
    if ($upluginObj.Plugins -and $upluginObj.Plugins.Count -gt 3) {
        $PluginArrayList = [System.Collections.ArrayList]$upluginObj.Plugins
        # Remove in reverse order to maintain correct indices
        $PluginArrayList.RemoveAt(3)
        $PluginArrayList.RemoveAt(2)
        $PluginArrayList.RemoveAt(1)
        $upluginObj.Plugins = $PluginArrayList
        $modified = $true
    } else {
        Write-Host "[version.ps1] WARNING: Expected at least 4 plugins but found $($upluginObj.Plugins.Count)"
    }
}

# For UE 4.20-4.27, 5.0-5.1: Remove module entries (indices 4, 3, 2)
if ($EngineVersion -eq '5.1' -or $EngineVersion -eq '5.0' -or 
    $EngineVersion -eq '4.27' -or $EngineVersion -eq '4.26' -or $EngineVersion -eq '4.25' -or $EngineVersion -eq '4.24' -or 
    $EngineVersion -eq '4.23' -or $EngineVersion -eq '4.22' -or $EngineVersion -eq '4.21' -or $EngineVersion -eq '4.20') {
    
    Write-Host "[version.ps1] UE $EngineVersion detected - removing modules at indices 4, 3, 2"
    if ($upluginObj.Modules.Count -gt 4) {
        $ModuleArrayList = [System.Collections.ArrayList]$upluginObj.Modules
        # Remove in reverse order to maintain correct indices
        $ModuleArrayList.RemoveAt(4)
        $ModuleArrayList.RemoveAt(3)
        $ModuleArrayList.RemoveAt(2)
        $upluginObj.Modules = $ModuleArrayList
        $modified = $true
    } else {
        Write-Host "[version.ps1] WARNING: Expected at least 5 modules but found $($upluginObj.Modules.Count)"
    }
}

# Write back the modified .uplugin file
if ($modified) {
    Write-Host "[version.ps1] Writing modified VRM4U.uplugin..."
    if (-not (Write-JsonFileSafe -JsonObject $upluginObj -FilePath $upluginPath)) {
        Write-Host "[version.ps1] ERROR: Failed to write modified VRM4U.uplugin"
        exit 1
    }
} else {
    Write-Host "[version.ps1] No modifications needed for VRM4U.uplugin"
}

Write-Host "[version.ps1] Completed successfully"
exit 0

