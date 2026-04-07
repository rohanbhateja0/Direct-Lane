<#
.SYNOPSIS
    Gets all languages from Sitecore and exports them to Excel.

.DESCRIPTION
    This script retrieves all languages from the Sitecore system languages folder,
    collects relevant information about each language, and exports the data to an Excel file
    that is automatically downloaded to your computer.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-Languages.ps1
#>

begin {
	Write-Verbose "Cmdlet Get-Languages - Begin"
	
	# ============================================================================
	# EXCEL EXPORT SETTINGS
	# ============================================================================
	# Note: Files are created in Sitecore's package folder and automatically
	# downloaded to your computer (similar to package downloads).
	# The file will be saved with a timestamp in the filename.
	# ============================================================================
	
	# Function to export languages to Excel/CSV and download to client
	function Export-LanguagesToExcel {
		param(
			[Parameter(Mandatory = $true)]
			[array]$Languages
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
			$baseFileName = "Sitecore_Languages_$timestamp"
			
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
			foreach ($langItem in $Languages) {
				try {
					# Get language object for additional properties
					$lang = [Sitecore.Data.Managers.LanguageManager]::GetLanguage($langItem.Name)
					$displayName = ""
					$cultureInfo = $null
					
					if ($lang) {
						$displayName = $lang.GetDisplayName()
						try {
							$cultureInfo = [Sitecore.Globalization.Language]::CreateCultureInfo($langItem.Name)
						}
						catch {
							# Culture info may not be available for all languages
						}
					}
					
					# Get additional fields from the language item
					$regionalIsoCode = ""
					$writingSystem = ""
					$readingDirection = ""
					
					if ($langItem.Fields["Regional Iso Code"]) {
						$regionalIsoCode = $langItem.Fields["Regional Iso Code"].Value
					}
					if ($langItem.Fields["Writing System"]) {
						$writingSystem = $langItem.Fields["Writing System"].Value
					}
					if ($langItem.Fields["Reading Direction"]) {
						$readingDirection = $langItem.Fields["Reading Direction"].Value
					}
					
					# Get culture-specific information if available
					$cultureName = ""
					$englishName = ""
					$nativeName = ""
					$twoLetterIsoLanguageName = ""
					$threeLetterIsoLanguageName = ""
					
					if ($cultureInfo) {
						$cultureName = $cultureInfo.Name
						$englishName = $cultureInfo.EnglishName
						$nativeName = $cultureInfo.NativeName
						$twoLetterIsoLanguageName = $cultureInfo.TwoLetterISOLanguageName
						$threeLetterIsoLanguageName = $cultureInfo.ThreeLetterISOLanguageName
					}
					
					$exportData += [PSCustomObject]@{
						LanguageCode = $langItem.Name
						DisplayName = $displayName
						ID = $langItem.ID.ToString()
						Path = $langItem.Paths.FullPath
						TemplateName = $langItem.TemplateName
						RegionalIsoCode = $regionalIsoCode
						WritingSystem = $writingSystem
						ReadingDirection = $readingDirection
						CultureName = $cultureName
						EnglishName = $englishName
						NativeName = $nativeName
						TwoLetterISOLanguageName = $twoLetterIsoLanguageName
						ThreeLetterISOLanguageName = $threeLetterIsoLanguageName
					}
				}
				catch {
					Write-Warning "Error processing language $($langItem.Name): $($_.Exception.Message)"
					# Still add basic information even if there's an error
					$exportData += [PSCustomObject]@{
						LanguageCode = $langItem.Name
						DisplayName = ""
						ID = $langItem.ID.ToString()
						Path = $langItem.Paths.FullPath
						TemplateName = $langItem.TemplateName
						RegionalIsoCode = ""
						WritingSystem = ""
						ReadingDirection = ""
						CultureName = ""
						EnglishName = ""
						NativeName = ""
						TwoLetterISOLanguageName = ""
						ThreeLetterISOLanguageName = ""
					}
				}
			}
			
			$serverFilePath = $null
			
			if ($useImportExcel) {
				# Use ImportExcel module to create .xlsx file
				$fileName = "$baseFileName.xlsx"
				$serverFilePath = Join-Path $SitecorePackageFolder $fileName
				Write-Host "`nCreating Excel file on server: $serverFilePath" -ForegroundColor Cyan
				
				$exportData | Export-Excel -Path $serverFilePath -WorksheetName "Languages" -AutoSize -FreezeTopRow -BoldTopRow
				
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
	Write-Verbose "Cmdlet Get-Languages - Process"

	Write-Host "`nRetrieving all languages from Sitecore..." -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Get all language items from Sitecore
	$languagesPath = "/sitecore/system/languages"
	
	if (-not (Test-Path -Path $languagesPath)) {
		Write-Error "Languages path not found: $languagesPath"
		return
	}
	
	$languageItems = Get-ChildItem -Path $languagesPath
	
	if ($languageItems.Count -eq 0) {
		Write-Host "`nNo languages found in Sitecore." -ForegroundColor Yellow
		return
	}
	
	Write-Host "`nFound $($languageItems.Count) language(s):`n" -ForegroundColor Green
	
	$index = 1
	foreach ($langItem in $languageItems) {
		try {
			$lang = [Sitecore.Data.Managers.LanguageManager]::GetLanguage($langItem.Name)
			$displayName = ""
			if ($lang) {
				$displayName = $lang.GetDisplayName()
			}
			
			Write-Host "[$index] $($langItem.Name)" -ForegroundColor Cyan
			if ($displayName) {
				Write-Host "     Display Name: $displayName" -ForegroundColor Gray
			}
			Write-Host "     Path: $($langItem.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     ID: $($langItem.ID)" -ForegroundColor Gray
			Write-Host ""
			
			$index++
		}
		catch {
			Write-Host "[$index] $($langItem.Name) (Error: $($_.Exception.Message))" -ForegroundColor Yellow
			$index++
		}
	}

	# Export to Excel and download to client
	$excelPath = Export-LanguagesToExcel -Languages $languageItems
	if ($excelPath) {
		Write-Host "`nLanguages exported to Excel successfully!" -ForegroundColor Green
	}

	# Return the languages as output
	return $languageItems
}

end {
	Write-Verbose "Cmdlet Get-Languages - End"
}

