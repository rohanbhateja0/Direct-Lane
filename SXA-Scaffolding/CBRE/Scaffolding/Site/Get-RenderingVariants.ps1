<#
.SYNOPSIS
    Gets all SXA Rendering variants under a specified path and exports them to Excel.

.DESCRIPTION
    This script retrieves all items with template ID {E1A3B30C-77BC-4F6C-A008-D01B3371235D}
    under the path /sitecore/content/CBRE/Shared/Shared Content/Presentation/Rendering-Variants,
    collects the item path and immediate child count (variants), and exports the data to an Excel file
    that is automatically downloaded to your computer.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-RenderingVariants.ps1

.EXAMPLE
    # Use Path parameter to specify a different path
    .\Get-RenderingVariants.ps1 -Path "/sitecore/content/CBRE/Shared/Shared Content/Presentation/Rendering-Variants"
#>

param(
	[Parameter(Mandatory = $false, Position = 0)]
	[string]$Path
)

begin {
	Write-Verbose "Cmdlet Get-RenderingVariants - Begin"
	
	# ============================================================================
	# VARIABLE FOR ITEM PATH - MODIFY THIS FOR ISE USAGE
	# ============================================================================
	# Set this variable to a specific path
	# Leave empty ("") to use Path parameter or default path
	# Example: $script:itemPath = "/sitecore/content/CBRE/Shared/Shared Content/Presentation/Rendering-Variants"
	# ============================================================================
	$script:itemPath = "/sitecore/content/CBRE/Shared/Shared Content/Presentation/Rendering-Variants"
	
	# Template ID for SXA Rendering Variants
	[Sitecore.Data.ID]$renderingVariantTemplateID = "{E1A3B30C-77BC-4F6C-A008-D01B3371235D}"
	
	# ============================================================================
	# EXCEL EXPORT SETTINGS
	# ============================================================================
	# Note: Files are created in Sitecore's package folder and automatically
	# downloaded to your computer (similar to package downloads).
	# The file will be saved with a timestamp in the filename.
	# ============================================================================
	
	# Function to export rendering variants to Excel/CSV and download to client
	function Export-RenderingVariantsToExcel {
		param(
			[Parameter(Mandatory = $true)]
			[array]$RenderingVariants
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
			$baseFileName = "SXA_Rendering_Variants_$timestamp"
			
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
			foreach ($variantItem in $RenderingVariants) {
				try {
					# Get immediate child count (not recursive) - these are the variants
					$childCount = (Get-ChildItem -Path $variantItem.Paths.FullPath -ErrorAction SilentlyContinue).Count
					
					$exportData += [PSCustomObject]@{
						ItemPath = $variantItem.Paths.FullPath
						VariantCount = $childCount
					}
				}
				catch {
					Write-Warning "Error processing item $($variantItem.Paths.FullPath): $($_.Exception.Message)"
					# Still add basic information even if there's an error
					$exportData += [PSCustomObject]@{
						ItemPath = $variantItem.Paths.FullPath
						VariantCount = 0
					}
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "Rendering Variants" -AutoSize -FreezeTopRow -BoldTopRow
				
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
	Write-Verbose "Cmdlet Get-RenderingVariants - Process"

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
		$targetPath = "/sitecore/content/CBRE/Shared/Shared Content/Presentation/Rendering-Variants"
		Write-Host "Using default path: $targetPath" -ForegroundColor Cyan
	}
	
	# Validate the path exists
	if (-not (Test-Path -Path $targetPath)) {
		Write-Error "Path not found: $targetPath"
		return
	}

	Write-Host "`nRetrieving SXA Rendering Variants from: $targetPath" -ForegroundColor Yellow
	Write-Host "Template ID: $renderingVariantTemplateID" -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Get all items recursively under the path
	$allItems = Get-ChildItem -Path $targetPath -Recurse

	# Filter for items with the specified template ID
	$renderingVariants = @()
	
	foreach ($item in $allItems) {
		if ($item.TemplateID -eq $renderingVariantTemplateID) {
			$renderingVariants += $item
		}
	}

	# Display results
	if ($renderingVariants.Count -eq 0) {
		Write-Host "`nNo rendering variants found with template ID $renderingVariantTemplateID." -ForegroundColor Yellow
		return
	}
	
	Write-Host "`nFound $($renderingVariants.Count) rendering variant item(s):`n" -ForegroundColor Green
	
	$index = 1
	foreach ($variantItem in $renderingVariants) {
		try {
			# Get immediate child count (not recursive)
			$childCount = (Get-ChildItem -Path $variantItem.Paths.FullPath -ErrorAction SilentlyContinue).Count
			
			Write-Host "[$index] $($variantItem.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($variantItem.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     ID: $($variantItem.ID)" -ForegroundColor Gray
			Write-Host "     Variant Count: $childCount" -ForegroundColor Gray
			Write-Host ""
			
			$index++
		}
		catch {
			Write-Host "[$index] $($variantItem.Name) (Error: $($_.Exception.Message))" -ForegroundColor Yellow
			$index++
		}
	}

	# Export to Excel and download to client
	$excelPath = Export-RenderingVariantsToExcel -RenderingVariants $renderingVariants
	if ($excelPath) {
		Write-Host "`nRendering variants exported to Excel successfully!" -ForegroundColor Green
	}

	# Return the rendering variants as output
	return $renderingVariants
}

end {
	Write-Verbose "Cmdlet Get-RenderingVariants - End"
}

