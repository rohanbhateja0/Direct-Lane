<#
.SYNOPSIS
    Gets the total number of pages from SharedSitemap files in the media library and exports to Excel.

.DESCRIPTION
    This script retrieves all sitemap files from the media library path, filters for files starting with "SharedSitemap-",
    processes all files, parses each XML sitemap, counts the number of pages (URLs), and exports the data to an Excel file
    that is automatically downloaded to your computer.

.PARAMETER SitemapPath
    Optional path to the sitemap folder. If not specified, uses the default path.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-PageCountFromSharedSitemap.ps1

.EXAMPLE
    # Use SitemapPath parameter to specify a different path
    .\Get-PageCountFromSharedSitemap.ps1 -SitemapPath "/sitecore/media library/Project/CBRE/Shared-Site/Emerald-Sitemaps"
#>

param(
	[Parameter(Mandatory = $false, Position = 0)]
	[string]$SitemapPath
)

begin {
	Write-Verbose "Cmdlet Get-PageCountFromSharedSitemap - Begin"
	
	# ============================================================================
	# VARIABLE FOR SITEMAP PATH - MODIFY THIS FOR ISE USAGE
	# ============================================================================
	# Set this variable to a specific path
	# Leave empty ("") to use SitemapPath parameter or default path
	# ============================================================================
	$script:sitemapPath = "/sitecore/media library/Project/CBRE/Shared-Site/Emerald-Sitemaps"
	
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
			[array]$SitemapPageCounts
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
			$baseFileName = "SharedSitemap_PageCounts_$timestamp"
			
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
			foreach ($sitemapInfo in $SitemapPageCounts) {
				try {
					$exportData += [PSCustomObject]@{
						SitemapFileName = $sitemapInfo.SitemapFileName
						SitemapPath = $sitemapInfo.SitemapPath
						SitemapID = $sitemapInfo.SitemapID
						PageCount = $sitemapInfo.PageCount
						Database = $sitemapInfo.Database
					}
				}
				catch {
					Write-Warning "Error processing sitemap $($sitemapInfo.SitemapFileName): $($_.Exception.Message)"
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "SharedSitemap Page Counts" -AutoSize -FreezeTopRow -BoldTopRow
				
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
	
	# Function to count pages from a sitemap XML file
	function Get-PageCountFromSitemap {
		param(
			[Parameter(Mandatory = $true)]
			[Sitecore.Data.Items.MediaItem]$MediaItem
		)
		
		try {
			# Get the media file stream
			$mediaStream = $MediaItem.GetMediaStream()
			if ($null -eq $mediaStream) {
				Write-Warning "Could not read media stream for $($MediaItem.Name)"
				return 0
			}
			
			# Read the XML content
			$reader = New-Object System.IO.StreamReader($mediaStream)
			$xmlContent = $reader.ReadToEnd()
			$reader.Close()
			$mediaStream.Close()
			
			# Parse the XML
			[xml]$xmlDoc = $xmlContent
			
			# Create namespace manager to handle XML namespaces
			$nsManager = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
			$nsManager.AddNamespace("sm", "https://www.sitemaps.org/schemas/sitemap/0.9")
			$nsManager.AddNamespace("xhtml", "https://www.w3.org/1999/xhtml")
			
			# Count URLs in the sitemap by counting <loc> elements (most reliable method)
			# Each <loc> represents a page URL
			$pageCount = 0
			
			# Method 1: Count <loc> elements with namespace
			$locNodes = $xmlDoc.SelectNodes("//sm:loc", $nsManager)
			if ($locNodes -and $locNodes.Count -gt 0) {
				$pageCount = $locNodes.Count
			}
			# Method 2: If no results with namespace, try without namespace
			else {
				$locNodes = $xmlDoc.SelectNodes("//loc")
				if ($locNodes -and $locNodes.Count -gt 0) {
					$pageCount = $locNodes.Count
				}
			}
			
			# Method 3: If still no results, try counting <url> elements
			if ($pageCount -eq 0) {
				$urlNodes = $xmlDoc.SelectNodes("//sm:url", $nsManager)
				if ($urlNodes -and $urlNodes.Count -gt 0) {
					$pageCount = $urlNodes.Count
				}
				else {
					$urlNodes = $xmlDoc.SelectNodes("//url")
					if ($urlNodes -and $urlNodes.Count -gt 0) {
						$pageCount = $urlNodes.Count
					}
				}
			}
			
			# Check for sitemap index if no URLs found
			if ($pageCount -eq 0) {
				$sitemapNodes = $xmlDoc.SelectNodes("//sm:sitemap", $nsManager)
				if ($sitemapNodes -and $sitemapNodes.Count -gt 0) {
					# This is a sitemap index, count the referenced sitemaps
					$pageCount = $sitemapNodes.Count
					Write-Host "     Note: This is a sitemap index file with $pageCount referenced sitemaps" -ForegroundColor Yellow
				}
				else {
					# Try without namespace
					$sitemapNodes = $xmlDoc.SelectNodes("//sitemap")
					if ($sitemapNodes -and $sitemapNodes.Count -gt 0) {
						$pageCount = $sitemapNodes.Count
						Write-Host "     Note: This is a sitemap index file with $pageCount referenced sitemaps" -ForegroundColor Yellow
					}
				}
			}
			
			return $pageCount
		}
		catch {
			Write-Warning "Error parsing sitemap $($MediaItem.Name): $($_.Exception.Message)"
			return 0
		}
	}
}

process {
	Write-Verbose "Cmdlet Get-PageCountFromSharedSitemap - Process"

	# Get the folder path - prioritize variable, then parameter, then default
	$targetPath = $null
	
	# Check variable first (for ISE usage)
	if (-not [string]::IsNullOrWhiteSpace($script:sitemapPath)) {
		$targetPath = $script:sitemapPath
		Write-Host "Using sitemapPath variable: $targetPath" -ForegroundColor Cyan
	}
	# Then check parameter
	elseif (-not [string]::IsNullOrWhiteSpace($SitemapPath)) {
		$targetPath = $SitemapPath
		Write-Host "Using SitemapPath parameter: $targetPath" -ForegroundColor Cyan
	}
	# Finally use default path
	else {
		$targetPath = "/sitecore/media library/Project/CBRE/Shared-Site/Emerald-Sitemaps"
		Write-Host "Using default path: $targetPath" -ForegroundColor Cyan
	}
	
	# Validate the path exists
	if (-not (Test-Path -Path $targetPath)) {
		Write-Error "Path not found: $targetPath"
		return
	}

	Write-Host "`nRetrieving SharedSitemap files from: $targetPath" -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Get all items in the sitemap folder
	$allItems = Get-ChildItem -Path $targetPath -ErrorAction SilentlyContinue
	
	if ($null -eq $allItems -or $allItems.Count -eq 0) {
		Write-Host "`nNo items found in the sitemap folder." -ForegroundColor Yellow
		return
	}
	
	# Filter for items starting with "SharedSitemap-"
	$sharedSitemapItems = $allItems | Where-Object { $_.Name -like "SharedSitemap-*" }
	
	if ($null -eq $sharedSitemapItems -or $sharedSitemapItems.Count -eq 0) {
		Write-Host "`nNo sitemap files found starting with 'SharedSitemap-'." -ForegroundColor Yellow
		return
	}
	
	Write-Host "`nFound $($sharedSitemapItems.Count) sitemap file(s) starting with 'SharedSitemap-'." -ForegroundColor Green
	Write-Host "Processing all files...`n" -ForegroundColor Cyan
	
	# Process all files
	$sitemapPageCounts = @()
	$index = 1
	$totalPages = 0
	
	foreach ($fileItem in $sharedSitemapItems) {
		try {
			# Convert to MediaItem if needed
			$mediaItem = $null
			if ($fileItem -is [Sitecore.Data.Items.MediaItem]) {
				$mediaItem = $fileItem
			}
			else {
				# Try to get as MediaItem
				try {
					$mediaItem = [Sitecore.Data.Items.MediaItem]$fileItem
				}
				catch {
					Write-Host "[$index/$($sharedSitemapItems.Count)] Skipping $($fileItem.Name) - Not a media item" -ForegroundColor Yellow
					$index++
					continue
				}
			}
			
			Write-Host "[$index/$($sharedSitemapItems.Count)] Processing: $($mediaItem.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($mediaItem.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     Extension: $($mediaItem.Extension)" -ForegroundColor Gray
			
			# Count pages from the sitemap
			$pageCount = Get-PageCountFromSitemap -MediaItem $mediaItem
			$totalPages += $pageCount
			
			Write-Host "     Page Count: $pageCount" -ForegroundColor Green
			Write-Host ""
			
			$sitemapPageCounts += [PSCustomObject]@{
				SitemapFileName = $mediaItem.Name
				SitemapPath = $mediaItem.Paths.FullPath
				SitemapID = $mediaItem.ID.ToString()
				PageCount = $pageCount
				Database = $mediaItem.Database.Name
			}
			
			$index++
		}
		catch {
			Write-Host "[$index/$($sharedSitemapItems.Count)] Error processing $($fileItem.Name): $($_.Exception.Message)" -ForegroundColor Red
			$sitemapPageCounts += [PSCustomObject]@{
				SitemapFileName = $fileItem.Name
				SitemapPath = $fileItem.Paths.FullPath
				SitemapID = $fileItem.ID.ToString()
				PageCount = 0
				Database = $fileItem.Database.Name
			}
			$index++
		}
	}
	
	# Display summary
	Write-Host "================================================" -ForegroundColor Yellow
	Write-Host "Summary:" -ForegroundColor Green
	Write-Host "  Total SharedSitemap Files Processed: $($sitemapPageCounts.Count)" -ForegroundColor Green
	Write-Host "  Total Pages Across All Sitemaps: $totalPages" -ForegroundColor Green
	Write-Host "================================================" -ForegroundColor Yellow
	
	# Export to Excel and download to client
	$excelPath = Export-PageCountsToExcel -SitemapPageCounts $sitemapPageCounts
	if ($excelPath) {
		Write-Host "`nSharedSitemap page counts exported to Excel successfully!" -ForegroundColor Green
	}
	
	# Return the results
	return $sitemapPageCounts
}

end {
	Write-Verbose "Cmdlet Get-PageCountFromSharedSitemap - End"
}

