<#
.SYNOPSIS
    Gets a list of components (renderings) under a specified folder.

.DESCRIPTION
    This script searches recursively for components under a folder. Components are identified as items
    that inherit from Controller Rendering, View Rendering, or Rendering Options Section templates.

.PARAMETER Path
    Optional path to the folder. If not specified, uses the itemPath variable or current context item.

.EXAMPLE
    # In ISE: Set the itemPath variable in the begin block (line 15) or run:
    $itemPath = "/sitecore/layout/Renderings/Feature"
    .\Get-Components.ps1

.EXAMPLE
    # Use current context item (select an item in Content Editor first)
    .\Get-Components.ps1

.EXAMPLE
    # Use Path parameter
    .\Get-Components.ps1 -Path "/sitecore/layout/Renderings/Feature"
#>

param(
	[Parameter(Mandatory = $false, Position = 0)]
	[string]$Path
)

begin {
	Write-Verbose "Cmdlet Get-Components - Begin"
	Import-Function Select-InheritingFrom
	
	# ============================================================================
	# VARIABLE FOR ITEM PATH - MODIFY THIS FOR ISE USAGE
	# ============================================================================
	# Set this variable to a specific path like "/sitecore/layout/Renderings/Feature"
	# Leave empty ("") to use current context item or Path parameter
	# Example: $script:itemPath = "/sitecore/layout/Renderings/Feature"
	# ============================================================================
	$script:itemPath = "/sitecore/layout/Renderings/Feature/CBRE"
	
	# ============================================================================
	# EXCEL EXPORT SETTINGS
	# ============================================================================
	# Note: Files are created in Sitecore's package folder and automatically
	# downloaded to your computer (similar to package downloads).
	# The file will be saved with a timestamp in the filename.
	# ============================================================================
	
	# Function to export components to Excel/CSV and download to client
	function Export-ComponentsToExcel {
		param(
			[Parameter(Mandatory = $true)]
			[array]$Components
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
			$baseFileName = "Components_$timestamp"
			
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
			foreach ($component in $Components) {
				$exportData += [PSCustomObject]@{
					Name = $component.Name
					ID = $component.ID.ToString()
					TemplateName = $component.TemplateName
					Path = $component.Paths.FullPath
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "Components" -AutoSize -FreezeTopRow -BoldTopRow
				
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
	Write-Verbose "Cmdlet Get-Components - Process"

	# Get the folder path - prioritize variable, then parameter, then current item
	$folderItem = $null
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
	# Finally use current context item
	else {
		$folderItem = Get-Item .
		Write-Host "Using current folder context: $($folderItem.Paths.FullPath)" -ForegroundColor Cyan
	}
	
	# If we have a target path, get the item
	if ($null -ne $targetPath) {
		# Validate the path exists
		if (-not (Test-Path -Path $targetPath)) {
			Write-Error "Path not found: $targetPath"
			return
		}
		$folderItem = Get-Item -Path $targetPath
	}

	Write-Host "`nSearching for components under: $($folderItem.Paths.FullPath)" -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Template IDs for rendering types
	[Sitecore.Data.ID]$controllerRenderingTemplateID = "{2A3E91A0-7987-44B5-AB34-35C2D9DE83B9}"
	[Sitecore.Data.ID]$viewRenderingTemplateID = "{A87A00B1-E6DB-45AB-8B54-636FEC3B5523}"
	[Sitecore.Data.ID]$renderingOptionsSectionTemplateID = "{D1592226-3898-4CE2-B190-090FD5F84A4C}"

	# Get all items recursively under the folder
	$allItems = Get-ChildItem -Path $folderItem.Paths.FullPath -Recurse

	# Filter for components (items that inherit from rendering templates)
	$components = @()
	
	foreach ($item in $allItems) {
		$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item.TemplateID, $item.Database)
		
		# Check if item inherits from Controller Rendering or View Rendering templates
		if ($template.InheritsFrom($controllerRenderingTemplateID) -or 
			$template.InheritsFrom($viewRenderingTemplateID) -or
			$template.InheritsFrom($renderingOptionsSectionTemplateID)) {
			$components += $item
		}
	}

	# Display results
	if ($components.Count -eq 0) {
		Write-Host "`nNo components found under the specified folder." -ForegroundColor Yellow
	}
	else {
		Write-Host "`nFound $($components.Count) component(s):`n" -ForegroundColor Green
		
		$index = 1
		
		foreach ($component in $components) {
			Write-Host "[$index] $($component.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($component.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     ID: $($component.ID)" -ForegroundColor Gray
			Write-Host "     Template: $($component.TemplateName)" -ForegroundColor Gray
			Write-Host ""
			
			$index++
		}

		# Export to Excel and download to client
		$excelPath = Export-ComponentsToExcel -Components $components
		if ($excelPath) {
			Write-Host "`nComponents exported to Excel successfully!" -ForegroundColor Green
		}

		# Return the components as output
		return $components
	}
}

end {
	Write-Verbose "Cmdlet Get-Components - End"
}

