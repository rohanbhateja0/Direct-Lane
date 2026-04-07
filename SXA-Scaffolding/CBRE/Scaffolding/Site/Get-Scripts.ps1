<#
.SYNOPSIS
    Gets all PowerShell scripts from Sitecore and exports them to Excel.

.DESCRIPTION
    This script retrieves all items with template ID {DD22F1B3-BD87-4DB2-9E7D-F7A496888D43}
    under the path /sitecore/system/Modules/PowerShell/Script Library/CBRE,
    collects relevant information about each script, and exports the data to an Excel file
    that is automatically downloaded to your computer.

.PARAMETER Path
    Optional path to the scripts folder. If not specified, uses the default path.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-Scripts.ps1

.EXAMPLE
    # Use Path parameter to specify a different path
    .\Get-Scripts.ps1 -Path "/sitecore/system/Modules/PowerShell/Script Library/CBRE"
#>

param(
	[Parameter(Mandatory = $false, Position = 0)]
	[string]$Path
)

begin {
	Write-Verbose "Cmdlet Get-Scripts - Begin"
	
	# ============================================================================
	# VARIABLE FOR ITEM PATH - MODIFY THIS FOR ISE USAGE
	# ============================================================================
	# Set this variable to a specific path
	# Leave empty ("") to use Path parameter or default path
	# ============================================================================
	$script:itemPath = "/sitecore/system/Modules/PowerShell/Script Library/CBRE"
	
	# Template ID for PowerShell scripts
	[Sitecore.Data.ID]$scriptTemplateID = "{DD22F1B3-BD87-4DB2-9E7D-F7A496888D43}"
	
	# ============================================================================
	# EXCEL EXPORT SETTINGS
	# ============================================================================
	# Note: Files are created in Sitecore's package folder and automatically
	# downloaded to your computer (similar to package downloads).
	# The file will be saved with a timestamp in the filename.
	# ============================================================================
	
	# Function to export scripts to Excel/CSV and download to client
	function Export-ScriptsToExcel {
		param(
			[Parameter(Mandatory = $true)]
			[array]$Scripts
		)
		
		try {
			# Get Sitecore package folder (where temporary files are stored for download)
			$SitecorePackageFolder = [Sitecore.Configuration.Settings]::GetSetting("PackagePath")
			if ([string]::IsNullOrWhiteSpace($SitecorePackageFolder)) {
				# Fallback to Data\packages if setting is not available
				$SitecorePackageFolder = [Sitecore.IO.FileUtil]::MapPath("/sitecore/admin/packages")
			}
			
			# Ensure the package folder exists
			if (-not [System.IO.Directory]::Exists($SitecorePackageFolder)) {
				[System.IO.Directory]::CreateDirectory($SitecorePackageFolder) | Out-Null
			}
			
			# Generate filename with timestamp
			$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
			$baseFileName = "Sitecore_Scripts_$timestamp"
			
			# Check if ImportExcel module is available
			$useImportExcel = $false
			if (Get-Module -ListAvailable -Name ImportExcel) {
				try {
					Import-Module ImportExcel -ErrorAction Stop
					$useImportExcel = $true
					Write-Host "`nUsing ImportExcel module for export" -ForegroundColor Cyan
				}
				catch {
					Write-Host "ImportExcel module found but failed to import, using CSV export instead" -ForegroundColor Yellow
					$useImportExcel = $false
				}
			}
			
			# Prepare data for export
			$exportData = @()
			foreach ($scriptItem in $Scripts) {
				try {
					# Get script content if available
					$scriptContent = ""
					if ($scriptItem.Fields["Script"]) {
						$scriptContent = $scriptItem.Fields["Script"].Value
						# Truncate if too long (for Excel display)
						if ($scriptContent.Length -gt 32767) {
							$scriptContent = $scriptContent.Substring(0, 32767) + "... (truncated)"
						}
					}
					
					# Get additional fields
					$description = ""
					if ($scriptItem.Fields["__Long description"]) {
						$description = $scriptItem.Fields["__Long description"].Value
					}
					
					$exportData += [PSCustomObject]@{
						ScriptName = $scriptItem.Name
						ScriptPath = $scriptItem.Paths.FullPath
						ScriptID = $scriptItem.ID.ToString()
						TemplateName = $scriptItem.TemplateName
						Description = $description
						ScriptContent = $scriptContent
						Database = $scriptItem.Database.Name
					}
				}
				catch {
					Write-Warning "Error processing script $($scriptItem.Paths.FullPath): $($_.Exception.Message)"
					# Still add basic information even if there's an error
					$exportData += [PSCustomObject]@{
						ScriptName = $scriptItem.Name
						ScriptPath = $scriptItem.Paths.FullPath
						ScriptID = $scriptItem.ID.ToString()
						TemplateName = $scriptItem.TemplateName
						Description = ""
						ScriptContent = ""
						Database = $scriptItem.Database.Name
					}
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "Scripts" -AutoSize -FreezeTopRow -BoldTopRow
				
				Write-Host "Excel file created successfully on server" -ForegroundColor Green
			}
			else {
				# Fallback to CSV (Excel can open CSV files)
				$fileName = "$baseFileName.csv"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating CSV file on server: $serverFilePath" -ForegroundColor Cyan
				Write-Host "Note: CSV files can be opened directly in Excel" -ForegroundColor Yellow
				
				$exportData | Export-Csv -Path $serverFilePath -NoTypeInformation -Encoding UTF8
				
				Write-Host "CSV file created successfully on server" -ForegroundColor Green
			}
			
			# Download the file to the client (similar to package download)
			if (Test-Path $serverFilePath) {
				Write-Host "Downloading file to your computer..." -ForegroundColor Cyan
				Download-File $serverFilePath
				
				# Clean up the temporary file on server
				Start-Sleep -Milliseconds 500  # Give download time to start
				try {
					Remove-Item $serverFilePath -Force -ErrorAction SilentlyContinue
					Write-Host "Temporary file cleaned up from server" -ForegroundColor Gray
				}
				catch {
					Write-Host "Note: Temporary file may still exist on server: $serverFilePath" -ForegroundColor Yellow
				}
				
				Write-Host "File downloaded successfully!" -ForegroundColor Green
				return $serverFilePath
			}
			else {
				throw "File was not created on server: $serverFilePath"
			}
		}
		catch {
			Write-Error "Failed to export: $($_.Exception.Message)"
			Write-Host "Error details: $($_.Exception.GetType().FullName)" -ForegroundColor Red
			if ($_.Exception.InnerException) {
				Write-Host "Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
			}
			return $null
		}
	}
}

process {
	Write-Verbose "Cmdlet Get-Scripts - Process"

	# Get the folder path - prioritize variable, then parameter, then default
	$targetPath = $null
	
	# Check variable first (for ISE usage)
	if (-not [string]::IsNullOrWhiteSpace($script:itemPath)) {
		$targetPath = $script:itemPath
		Write-Host "Using itemPath variable: $targetPath" -ForegroundColor Cyan
	}
	# Then check parameter
	elseif (-not [string]::IsNullOrWhiteSpace($Path)) {
		$targetPath = $Path
		Write-Host "Using Path parameter: $targetPath" -ForegroundColor Cyan
	}
	# Finally use default path
	else {
		$targetPath = "/sitecore/system/Modules/PowerShell/Script Library/CBRE"
		Write-Host "Using default path: $targetPath" -ForegroundColor Cyan
	}
	
	# Validate the path exists
	if (-not (Test-Path -Path $targetPath)) {
		Write-Error "Path not found: $targetPath"
		return
	}

	Write-Host "`nRetrieving all scripts from: $targetPath" -ForegroundColor Yellow
	Write-Host "Template ID: $scriptTemplateID" -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Get all items recursively under the path
	$allItems = Get-ChildItem -Path $targetPath -Recurse

	# Filter for items with the specified template ID
	$scriptItems = @()
	
	foreach ($item in $allItems) {
		if ($item.TemplateID -eq $scriptTemplateID) {
			$scriptItems += $item
		}
	}

	# Display results
	if ($scriptItems.Count -eq 0) {
		Write-Host "`nNo scripts found with template ID $scriptTemplateID." -ForegroundColor Yellow
		return
	}
	
	Write-Host "`nFound $($scriptItems.Count) script(s):`n" -ForegroundColor Green
	
	$index = 1
	foreach ($scriptItem in $scriptItems) {
		try {
			Write-Host "[$index] $($scriptItem.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($scriptItem.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     ID: $($scriptItem.ID)" -ForegroundColor Gray
			Write-Host "     Template: $($scriptItem.TemplateName)" -ForegroundColor Gray
			Write-Host ""
			
			$index++
		}
		catch {
			Write-Host "[$index] $($scriptItem.Name) (Error: $($_.Exception.Message))" -ForegroundColor Yellow
			$index++
		}
	}

	# Export to Excel and download to client
	$excelPath = Export-ScriptsToExcel -Scripts $scriptItems
	if ($excelPath) {
		Write-Host "`nScripts exported to Excel successfully!" -ForegroundColor Green
	}

	# Return the scripts as output
	return $scriptItems
}

end {
	Write-Verbose "Cmdlet Get-Scripts - End"
}

