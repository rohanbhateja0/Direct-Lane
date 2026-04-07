<#
.SYNOPSIS
    Gets all template items from Sitecore and exports them to Excel.

.DESCRIPTION
    This script retrieves all template items from the Sitecore templates folder,
    collects the template path and name, and exports the data to an Excel file
    that is automatically downloaded to your computer.

.PARAMETER Path
    Optional path to the templates folder. If not specified, uses /sitecore/templates.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-Templates.ps1

.EXAMPLE
    # Use Path parameter to specify a different path
    .\Get-Templates.ps1 -Path "/sitecore/templates"
#>

param(
	[Parameter(Mandatory = $false, Position = 0)]
	[string]$Path
)

begin {
	Write-Verbose "Cmdlet Get-Templates - Begin"
	
	# ============================================================================
	# VARIABLE FOR ITEM PATH - MODIFY THIS FOR ISE USAGE
	# ============================================================================
	# Set this variable to a specific path like "/sitecore/templates"
	# Leave empty ("") to use Path parameter or default path
	# Example: $script:itemPath = "/sitecore/templates"
	# ============================================================================
	$script:itemPath = "/sitecore/templates/Project/CBRE/Pages"
	
	# ============================================================================
	# EXCEL EXPORT SETTINGS
	# ============================================================================
	# Note: Files are created in Sitecore's package folder and automatically
	# downloaded to your computer (similar to package downloads).
	# The file will be saved with a timestamp in the filename.
	# ============================================================================
	
	# Function to export templates to Excel/CSV and download to client
	function Export-TemplatesToExcel {
		param(
			[Parameter(Mandatory = $true)]
			[array]$Templates
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
			$baseFileName = "Sitecore_Templates_$timestamp"
			
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
			foreach ($templateItem in $Templates) {
				try {
					$exportData += [PSCustomObject]@{
						TemplatePath = $templateItem.Paths.FullPath
						Name = $templateItem.Name
					}
				}
				catch {
					Write-Warning "Error processing template $($templateItem.Paths.FullPath): $($_.Exception.Message)"
					# Still add basic information even if there's an error
					$exportData += [PSCustomObject]@{
						TemplatePath = $templateItem.Paths.FullPath
						Name = $templateItem.Name
					}
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "Templates" -AutoSize -FreezeTopRow -BoldTopRow
				
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
	Write-Verbose "Cmdlet Get-Templates - Process"

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
		$targetPath = "/sitecore/templates/Project/CBRE/Pages"
		Write-Host "Using default path: $targetPath" -ForegroundColor Cyan
	}
	
	# Validate the path exists
	if (-not (Test-Path -Path $targetPath)) {
		Write-Error "Path not found: $targetPath"
		return
	}

	Write-Host "`nRetrieving all templates from: $targetPath" -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Get all template items recursively under the path
	# Templates are items with template ID {AB86861A-6030-46C5-B394-E8F99E8B87DB}
	[Sitecore.Data.ID]$templateTemplateID = "{AB86861A-6030-46C5-B394-E8F99E8B87DB}"
	
	$allItems = Get-ChildItem -Path $targetPath -Recurse
	
	# Filter for template items
	$templateItems = @()
	
	foreach ($item in $allItems) {
		if ($item.TemplateID -eq $templateTemplateID) {
			$templateItems += $item
		}
	}

	# Display results
	if ($templateItems.Count -eq 0) {
		Write-Host "`nNo templates found." -ForegroundColor Yellow
		return
	}
	
	Write-Host "`nFound $($templateItems.Count) template(s):`n" -ForegroundColor Green
	
	$index = 1
	foreach ($templateItem in $templateItems) {
		try {
			Write-Host "[$index] $($templateItem.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($templateItem.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     ID: $($templateItem.ID)" -ForegroundColor Gray
			Write-Host ""
			
			$index++
		}
		catch {
			Write-Host "[$index] $($templateItem.Name) (Error: $($_.Exception.Message))" -ForegroundColor Yellow
			$index++
		}
	}

	# Export to Excel and download to client
	$excelPath = Export-TemplatesToExcel -Templates $templateItems
	if ($excelPath) {
		Write-Host "`nTemplates exported to Excel successfully!" -ForegroundColor Green
	}

	# Return the templates as output
	return $templateItems
}

end {
	Write-Verbose "Cmdlet Get-Templates - End"
}

