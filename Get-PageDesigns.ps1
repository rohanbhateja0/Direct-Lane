<#
.SYNOPSIS
    Gets all page designs from Sitecore under a specific path.

.DESCRIPTION
    This script retrieves all items with template ID {6D0AD74D-4A13-482B-BF6E-0FFFAE43628B}
    under the path /sitecore/content/CBRE/Shared/Shared Content/Presentation/Page-Designs.

.PARAMETER Path
    Optional path to the page designs folder. If not specified, uses the default path.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-PageDesigns.ps1

.EXAMPLE
    # Use Path parameter to specify a different path
    .\Get-PageDesigns.ps1 -Path "/sitecore/content/CBRE/Shared/Shared Content/Presentation/Page-Designs"
#>

param(
	[Parameter(Mandatory = $false, Position = 0)]
	[string]$Path
)

begin {
	Write-Verbose "Cmdlet Get-PageDesigns - Begin"
	
	# ============================================================================
	# VARIABLE FOR ITEM PATH - MODIFY THIS FOR ISE USAGE
	# ============================================================================
	# Set this variable to a specific path
	# Leave empty ("") to use Path parameter or default path
	# ============================================================================
	$script:itemPath = "/sitecore/content/CBRE/Shared/Shared Content/Presentation/Page-Designs"
	
	# Template ID for page designs
	[Sitecore.Data.ID]$pageDesignTemplateID = "{6D0AD74D-4A13-482B-BF6E-0FFFAE43628B}"
}

process {
	Write-Verbose "Cmdlet Get-PageDesigns - Process"

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
		$targetPath = "/sitecore/content/CBRE/Shared/Shared Content/Presentation/Page-Designs"
		Write-Host "Using default path: $targetPath" -ForegroundColor Cyan
	}
	
	# Validate the path exists
	if (-not (Test-Path -Path $targetPath)) {
		Write-Error "Path not found: $targetPath"
		return
	}

	Write-Host "`nRetrieving all page designs from: $targetPath" -ForegroundColor Yellow
	Write-Host "Template ID: $pageDesignTemplateID" -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	# Get all items recursively under the path
	$allItems = Get-ChildItem -Path $targetPath -Recurse

	# Filter for items with the specified template ID
	$pageDesignItems = @()
	
	foreach ($item in $allItems) {
		if ($item.TemplateID -eq $pageDesignTemplateID) {
			$pageDesignItems += $item
		}
	}

	# Display results
	if ($pageDesignItems.Count -eq 0) {
		Write-Host "`nNo page designs found with template ID $pageDesignTemplateID." -ForegroundColor Yellow
		return
	}
	
	Write-Host "`nFound $($pageDesignItems.Count) page design(s):`n" -ForegroundColor Green
	
	$index = 1
	foreach ($pageDesignItem in $pageDesignItems) {
		try {
			Write-Host "[$index] $($pageDesignItem.Name)" -ForegroundColor Cyan
			Write-Host "     Path: $($pageDesignItem.Paths.FullPath)" -ForegroundColor Gray
			Write-Host "     ID: $($pageDesignItem.ID)" -ForegroundColor Gray
			Write-Host "     Template: $($pageDesignItem.TemplateName)" -ForegroundColor Gray
			Write-Host ""
			
			$index++
		}
		catch {
			Write-Host "[$index] $($pageDesignItem.Name) (Error: $($_.Exception.Message))" -ForegroundColor Yellow
			$index++
		}
	}

	# Return the page designs as output
	return $pageDesignItems
}

end {
	Write-Verbose "Cmdlet Get-PageDesigns - End"
}

