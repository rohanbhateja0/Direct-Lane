<#
.SYNOPSIS
    Exports Sitecore PowerShell scripts from the SXA Scaffolding library to .ps1 files.

.DESCRIPTION
    This script retrieves all items under /sitecore/system/Modules/PowerShell/Script Library/SXA/SXA - Scaffolding/Functions/Scaffolding/Site/Theme
    that have the template ID {DD22F1B3-BD87-4DB2-9E7D-F7A496888D43}, extracts the "Script" field content,
    and saves it to individual .ps1 files named after each item.
    
    This script must be run from within Sitecore PowerShell Extension (SPE).

.PARAMETER OutputPath
    The directory path where the exported .ps1 files will be saved. If not specified, uses the script's directory.

.PARAMETER Database
    The Sitecore database to query. Defaults to "master".

.EXAMPLE
    .\Export-SitecoreScripts.ps1
    
.EXAMPLE
    .\Export-SitecoreScripts.ps1 -OutputPath "C:\ExportedScripts"
    
.EXAMPLE
    .\Export-SitecoreScripts.ps1 -OutputPath "C:\ExportedScripts" -Database "master"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$Database = "master"
)

# Set default output path if not provided
$defaultOutputPath = "C:\CBRE\Projects\Direct Lane"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = $defaultOutputPath
}

# Convert provider path to file system path if needed (e.g., master:\path -> file system path)
# Check if path contains a colon followed by backslash (provider path indicator)
if ($OutputPath -match '^[a-zA-Z]+:\\') {
    # Check if it's a provider path (like master:\content\Home)
    $providerName = $OutputPath.Split(':')[0]
    $psDrive = Get-PSDrive -Name $providerName -ErrorAction SilentlyContinue
    if ($psDrive -and $psDrive.Provider.Name -ne "FileSystem") {
        # It's a provider path, not a file system path - use default
        $OutputPath = $defaultOutputPath
        Write-Warning "Output path was a provider path. Using default: $OutputPath"
    }
}

# Template ID for PowerShell Script Library items
$scriptTemplateId = [Sitecore.Data.ID]::Parse("{DD22F1B3-BD87-4DB2-9E7D-F7A496888D43}")

# Base path in Sitecore
$basePath = "/sitecore/system/Modules/PowerShell/Script Library/SXA/SXA - Scaffolding/Functions/Scaffolding/Site/Theme"

# Ensure output directory exists using file system provider
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    # Convert to absolute path to ensure it's a valid file system path
    try {
        $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
        if (-not [System.IO.Directory]::Exists($OutputPath)) {
            Write-Verbose "Creating output directory: $OutputPath"
            [System.IO.Directory]::CreateDirectory($OutputPath) | Out-Null
        }
    } catch {
        Write-Error "Invalid output path: $OutputPath. Error: $_"
        $OutputPath = $defaultOutputPath
        Write-Warning "Using default output path: $OutputPath"
        if (-not [System.IO.Directory]::Exists($OutputPath)) {
            [System.IO.Directory]::CreateDirectory($OutputPath) | Out-Null
        }
    }
}

Write-Host "Starting export from: $basePath" -ForegroundColor Green
Write-Host "Output directory: $OutputPath" -ForegroundColor Green

try {
    # Get the base item using Sitecore PowerShell provider
    $baseItem = Get-Item -Path "$($Database):$basePath" -ErrorAction Stop
    Write-Verbose "Found base item: $($baseItem.Paths.Path)"
    
    # Get all child items recursively
    $allItems = Get-ChildItem -Path "$($Database):$basePath" -Recurse
    
    # Filter items by template ID (using Sitecore ID comparison)
    $scriptItems = $allItems | Where-Object { 
        $_.TemplateID -eq $scriptTemplateId 
    }
    
    Write-Host "Found $($scriptItems.Count) script items with template $scriptTemplateId" -ForegroundColor Cyan
    
    if ($scriptItems.Count -eq 0) {
        Write-Warning "No items found with template ID: $scriptTemplateId"
        return
    }
    
    $exportedCount = 0
    $skippedCount = 0
    
    # Process each script item
    foreach ($item in $scriptItems) {
        try {
            Write-Verbose "Processing item: $($item.Name) (ID: $($item.ID))"
            
            # Get the Script field value - try both field access methods for SPE compatibility
            $scriptContent = $null
            if ($item.Fields["Script"]) {
                $scriptContent = $item.Fields["Script"].Value
            } elseif ($item["Script"]) {
                $scriptContent = $item["Script"]
            }
            
            if ([string]::IsNullOrWhiteSpace($scriptContent)) {
                Write-Warning "Item '$($item.Name)' has no Script field content. Skipping."
                $skippedCount++
                continue
            }
            
            # Sanitize the item name for use as a filename
            $fileName = $item.Name
            # Remove invalid filename characters
            $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
            foreach ($char in $invalidChars) {
                $fileName = $fileName.Replace($char, '_')
            }
            
            # Ensure .ps1 extension
            if (-not $fileName.EndsWith(".ps1")) {
                $fileName = "$fileName.ps1"
            }
            
            # Full path for the output file - use .NET Path.Combine to ensure file system path
            $outputFile = [System.IO.Path]::Combine($OutputPath, $fileName)
            
            # Write the script content to file using .NET File class to ensure file system provider is used
            [System.IO.File]::WriteAllText($outputFile, $scriptContent, [System.Text.Encoding]::UTF8)
            
            Write-Host "Exported: $fileName" -ForegroundColor Green
            $exportedCount++
            
        } catch {
            Write-Error "Error processing item '$($item.Name)': $_"
            $skippedCount++
        }
    }
    
    Write-Host "`nExport completed!" -ForegroundColor Green
    Write-Host "  Exported: $exportedCount files" -ForegroundColor Cyan
    if ($skippedCount -gt 0) {
        Write-Host "  Skipped: $skippedCount items" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Error accessing Sitecore path '$basePath': $_"
    Write-Error "Make sure you are running this script from Sitecore PowerShell Extension (SPE)."
    throw
}

