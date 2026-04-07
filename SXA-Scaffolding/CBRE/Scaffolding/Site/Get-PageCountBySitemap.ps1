<#
.SYNOPSIS
    Gets the total number of pages for each SXA site using sitemap logic and exports to Excel.

.DESCRIPTION
    This script retrieves all SXA sites from Sitecore, counts pages (items inheriting from Page template)
    for each site by traversing the content tree (sitemap approach), and exports the data to an Excel file
    that is automatically downloaded to your computer.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-PageCountBySitemap.ps1
#>

begin {
	Write-Verbose "Cmdlet Get-PageCountBySitemap - Begin"
	
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
	
	# Function to export page counts to Excel/CSV and download to client
	function Export-PageCountsToExcel {
		param(
			[Parameter(Mandatory = $true)]
			[array]$SitePageCounts
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
			$baseFileName = "SXA_Site_PageCounts_$timestamp"
			
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
			foreach ($siteInfo in $SitePageCounts) {
				try {
					$exportData += [PSCustomObject]@{
						SiteName = $siteInfo.SiteName
						SitePath = $siteInfo.SitePath
						SiteID = $siteInfo.SiteID
						TotalPageCount = $siteInfo.PageCount
						Database = $siteInfo.Database
					}
				}
				catch {
					Write-Warning "Error processing site $($siteInfo.SitePath): $($_.Exception.Message)"
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "Page Counts" -AutoSize -FreezeTopRow -BoldTopRow
				
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
	
	# Function to count pages for a site using sitemap approach
	function Get-PageCountForSite {
		param(
			[Parameter(Mandatory = $true)]
			[Sitecore.Data.Items.Item]$SiteItem
		)
		
		try {
			# Get Page template ID
			[Sitecore.Data.ID]$pageTemplateID = [Sitecore.XA.Foundation.Multisite.Templates+Page]::ID
			
			# Get all items recursively under the site root (sitemap approach)
			$allItems = Get-ChildItem -Path $SiteItem.Paths.FullPath -Recurse -ErrorAction SilentlyContinue
			
			# Filter for items that inherit from Page template
			$pages = @()
			foreach ($item in $allItems) {
				try {
					$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item.TemplateID, $item.Database)
					if ($template -and $template.InheritsFrom($pageTemplateID)) {
						$pages += $item
					}
				}
				catch {
					# Skip items that can't be processed
					continue
				}
			}
			
			return $pages.Count
		}
		catch {
			Write-Warning "Error counting pages for site $($SiteItem.Paths.FullPath): $($_.Exception.Message)"
			return 0
		}
	}
}

process {
	Write-Verbose "Cmdlet Get-PageCountBySitemap - Process"

	Write-Host "`nRetrieving all SXA sites and counting pages..." -ForegroundColor Yellow
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
	
	Write-Host "`nFound $($uniqueSites.Count) SXA site(s). Counting pages for each site...`n" -ForegroundColor Green
	
	# Count pages for each site
	$sitePageCounts = @()
	$index = 1
	
	foreach ($siteItem in $uniqueSites) {
		try {
			Write-Host "[$index/$($uniqueSites.Count)] Processing: $($siteItem.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($siteItem.Paths.FullPath)" -ForegroundColor Gray
			
			# Count pages using sitemap approach
			$pageCount = Get-PageCountForSite -SiteItem $siteItem
			
			Write-Host "     Page Count: $pageCount" -ForegroundColor Green
			Write-Host ""
			
			$sitePageCounts += [PSCustomObject]@{
				SiteName = $siteItem.Name
				SitePath = $siteItem.Paths.FullPath
				SiteID = $siteItem.ID.ToString()
				PageCount = $pageCount
				Database = $siteItem.Database.Name
			}
			
			$index++
		}
		catch {
			Write-Host "[$index] Error processing site $($siteItem.Name): $($_.Exception.Message)" -ForegroundColor Yellow
			$sitePageCounts += [PSCustomObject]@{
				SiteName = $siteItem.Name
				SitePath = $siteItem.Paths.FullPath
				SiteID = $siteItem.ID.ToString()
				PageCount = 0
				Database = $siteItem.Database.Name
			}
			$index++
		}
	}
	
	# Calculate total pages across all sites
	$totalPages = ($sitePageCounts | Measure-Object -Property PageCount -Sum).Sum
	Write-Host "================================================" -ForegroundColor Yellow
	Write-Host "Total Pages Across All Sites: $totalPages" -ForegroundColor Green
	Write-Host "================================================" -ForegroundColor Yellow

	# Export to Excel and download to client
	$excelPath = Export-PageCountsToExcel -SitePageCounts $sitePageCounts
	if ($excelPath) {
		Write-Host "`nPage counts exported to Excel successfully!" -ForegroundColor Green
	}

	# Return the site page counts as output
	return $sitePageCounts
}

end {
	Write-Verbose "Cmdlet Get-PageCountBySitemap - End"
}

