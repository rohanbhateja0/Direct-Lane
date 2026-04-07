<#
.SYNOPSIS
    Gets all SXA sites from Sitecore and exports them to Excel.

.DESCRIPTION
    This script retrieves all SXA sites from Sitecore, collects relevant information
    about each site, and exports the data to an Excel file that is automatically
    downloaded to your computer.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-SxaSites.ps1
#>

begin {
	Write-Verbose "Cmdlet Get-SxaSites - Begin"
	
	# Import required functions
	Import-Function Select-InheritingFrom
	Import-Function Get-UniqueItem
	
	# ============================================================================
	# EXCEL EXPORT SETTINGS
	# ============================================================================
	# Note: Files are created in Sitecore's package folder and automatically
	# downloaded to your computer (similar to package downloads).
	# The file will be saved with a timestamp in the filename.
	# ============================================================================
	
	# Function to export SXA sites to Excel/CSV and download to client
	function Export-SxaSitesToExcel {
		param(
			[Parameter(Mandatory = $true)]
			[array]$Sites
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
			$baseFileName = "SXA_Sites_$timestamp"
			
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
			foreach ($siteItem in $Sites) {
				try {
					# Get additional site information
					$siteName = $siteItem.Name
					$sitePath = $siteItem.Paths.FullPath
					$siteId = $siteItem.ID.ToString()
					$templateName = $siteItem.TemplateName
					
					# Try to get site definition from SiteManager
					$siteDefinition = $null
					$rootPath = ""
					try {
						$sites = [Sitecore.Sites.SiteManager]::GetSites()
						foreach ($site in $sites) {
							if ($site.Properties["rootPath"] -and (Test-Path $site.Properties["rootPath"])) {
								$rootItem = Get-Item -Path $site.Properties["rootPath"]
								if ($rootItem.ID -eq $siteItem.ID) {
									$siteDefinition = $site
									$rootPath = $site.Properties["rootPath"]
									break
								}
							}
						}
					}
					catch {
						# Site may not be registered in SiteManager
					}
					
					$exportData += [PSCustomObject]@{
						SiteName = $siteName
						SitePath = $sitePath
						SiteID = $siteId
						TemplateName = $templateName
						RootPath = $rootPath
						Database = $siteItem.Database.Name
					}
				}
				catch {
					Write-Warning "Error processing site $($siteItem.Paths.FullPath): $($_.Exception.Message)"
					# Still add basic information even if there's an error
					$exportData += [PSCustomObject]@{
						SiteName = $siteItem.Name
						SitePath = $siteItem.Paths.FullPath
						SiteID = $siteItem.ID.ToString()
						TemplateName = $siteItem.TemplateName
						RootPath = ""
						Database = $siteItem.Database.Name
					}
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "SXA Sites" -AutoSize -FreezeTopRow -BoldTopRow
				
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
	Write-Verbose "Cmdlet Get-SxaSites - Process"

	Write-Host "`nRetrieving all SXA sites from Sitecore..." -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Get SXA Site template ID
	$siteItemTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+Site]::ID
	
	# Get current database
	$database = (Get-Item .).Database
	$dbName = "master"
	if ($database) {
		$dbName = $database.Name
	}
	
	# Get all sites from SiteManager and filter for SXA sites
	$sites = [Sitecore.Sites.SiteManager]::GetSites() | 
		Where-Object { $_.Properties["rootPath"] -ne $null } | 
		Where-Object { (Test-Path $_.Properties["rootPath"]) -eq $true } | 
		ForEach-Object { 
			try {
				Get-Item -Path "$($dbName):$($_.Properties["rootPath"])"
			}
			catch {
				$null
			}
		} | 
		Where-Object { $_ -ne $null } | 
		Select-InheritingFrom $siteItemTemplateId
	
	# Remove duplicates
	$uniqueSites = Get-UniqueItem $sites

	# Display results
	if ($uniqueSites.Count -eq 0) {
		Write-Host "`nNo SXA sites found." -ForegroundColor Yellow
		return
	}
	
	Write-Host "`nFound $($uniqueSites.Count) SXA site(s):`n" -ForegroundColor Green
	
	$index = 1
	foreach ($siteItem in $uniqueSites) {
		try {
			Write-Host "[$index] $($siteItem.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($siteItem.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     ID: $($siteItem.ID)" -ForegroundColor Gray
			Write-Host "     Template: $($siteItem.TemplateName)" -ForegroundColor Gray
			Write-Host "     Database: $($siteItem.Database.Name)" -ForegroundColor Gray
			Write-Host ""
			
			$index++
		}
		catch {
			Write-Host "[$index] $($siteItem.Name) (Error: $($_.Exception.Message))" -ForegroundColor Yellow
			$index++
		}
	}

	# Export to Excel and download to client
	$excelPath = Export-SxaSitesToExcel -Sites $uniqueSites
	if ($excelPath) {
		Write-Host "`nSXA sites exported to Excel successfully!" -ForegroundColor Green
	}

	# Return the sites as output
	return $uniqueSites
}

end {
	Write-Verbose "Cmdlet Get-SxaSites - End"
}

