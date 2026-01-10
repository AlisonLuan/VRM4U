# Check if the project file exists (only needed for build_ver.bat, not build_ver2.bat)
$projectPath = "../../../../MyProjectBuildScript.uproject"
if (-not (Test-Path $projectPath)) {
    Write-Host "[version.ps1] MyProjectBuildScript.uproject not found - skipping (this is OK for plugin-only builds)"
    exit 0
}

# Read and parse the project file with error handling
try {
    $a = Get-Content $projectPath -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    
    # Verify we got a valid object
    if ($null -eq $a) {
        Write-Host "[version.ps1] Warning: Failed to parse project file as JSON - skipping"
        exit 0
    }
    
    $a
    
    # Ensure EngineAssociation property exists before trying to set it
    if (-not (Get-Member -InputObject $a -Name "EngineAssociation" -MemberType Properties)) {
        Write-Host "[version.ps1] Warning: EngineAssociation property not found in project file - adding it"
        $a | Add-Member -MemberType NoteProperty -Name "EngineAssociation" -Value ""
    }
    
    $a.EngineAssociation = $Args[0]
} catch {
    Write-Host "[version.ps1] Warning: Error reading/parsing project file: $_"
    Write-Host "[version.ps1] Skipping EngineAssociation update (this is OK for plugin-only builds)"
    exit 0
}

if ($a.EngineAssociation -eq '4.23' -or $a.EngineAssociation -eq '4.22' -or $a.EngineAssociation -eq '4.21' -or $a.EngineAssociation -eq '4.20')
{

    $b = Get-Content ../../../VRM4U/VRM4U.uplugin -Encoding UTF8 | ConvertFrom-Json
    $b

    $b.Modules[5].Type = 'Developer'

    $b | ConvertTo-Json > ../../../VRM4U/VRM4U.uplugin
}

if ($a.EngineAssociation -eq '4.27' -or $a.EngineAssociation -eq '4.26' -or $a.EngineAssociation -eq '4.25' -or $a.EngineAssociation -eq '4.24' -or $a.EngineAssociation -eq '4.23' -or $a.EngineAssociation -eq '4.22' -or $a.EngineAssociation -eq '4.21' -or $a.EngineAssociation -eq '4.20')
{

    $b = Get-Content ../../../VRM4U/VRM4U.uplugin -Encoding UTF8 | ConvertFrom-Json
    $b

    $PluginArrayList = [System.Collections.ArrayList]$b.Plugins
    $PluginArrayList.RemoveAt(3)
    $PluginArrayList.RemoveAt(2)
    $PluginArrayList.RemoveAt(1)
    $b.Plugins = $PluginArrayList

    $b | ConvertTo-Json > ../../../VRM4U/VRM4U.uplugin
}

if ($a.EngineAssociation -eq '5.1' -or $a.EngineAssociation -eq '5.0' -or $a.EngineAssociation -eq '4.27' -or $a.EngineAssociation -eq '4.26' -or $a.EngineAssociation -eq '4.25' -or $a.EngineAssociation -eq '4.24' -or $a.EngineAssociation -eq '4.23' -or $a.EngineAssociation -eq '4.22' -or $a.EngineAssociation -eq '4.21' -or $a.EngineAssociation -eq '4.20')
{

    $b = Get-Content ../../../VRM4U/VRM4U.uplugin -Encoding UTF8 | ConvertFrom-Json
    $b

    $ModuleArrayList = [System.Collections.ArrayList]$b.Modules
    $ModuleArrayList.RemoveAt(4)
    $ModuleArrayList.RemoveAt(3)
    $ModuleArrayList.RemoveAt(2)
    $b.Modules = $ModuleArrayList

    $b | ConvertTo-Json > ../../../VRM4U/VRM4U.uplugin
}


$a | ConvertTo-Json > $projectPath

