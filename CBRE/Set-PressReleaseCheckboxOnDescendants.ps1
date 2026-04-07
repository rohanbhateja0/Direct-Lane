<#
.SYNOPSIS
    Finds all Press Release pages and sets a checkbox field on each page and all descendants.

.DESCRIPTION
    Queries items using the Press Release template, then for each root collects the page itself
    and all descendants. For each item, if the template defines the checkbox field
    "__Should Not Organize In Bucket", that field is set to checked (including the Press Release
    page). The field is shared, so each item is updated once (not per language).
    Shows a Write-Progress bar while walking each subtree.

.PARAMETER ContentRoot
    Sitecore path (without database prefix) used as the root for the template query.
    Default is /sitecore/content.

.EXAMPLE
    .\Set-PressReleaseCheckboxOnDescendants.ps1

.EXAMPLE
    .\Set-PressReleaseCheckboxOnDescendants.ps1 -ContentRoot "/sitecore/content/CBRE/MySite"

.EXAMPLE
    .\Set-PressReleaseCheckboxOnDescendants.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[Parameter(Mandatory = $false)]
	[string]$ContentRoot = "/sitecore/content/CBRE/Shared/Shared Content/Home/Content/PressReleases"
)

begin {
	Write-Verbose "Set-PressReleaseCheckboxOnDescendants - Begin"

	[Sitecore.Data.ID]$pressReleaseTemplateId = "{2DAE7E5B-57D5-4A3B-935C-EC25F85D3772}"
	[string]$checkboxFieldName = "__Should Not Organize In Bucket"
}

process {
	# Descendants under ContentRoot (//* does not include the ContentRoot item itself)
	$queryDescendants = "$ContentRoot//*[@@templateid = '$pressReleaseTemplateId']"
	# Press Release page at ContentRoot path, if that item uses the template (//* misses self)
	$querySelf = "$ContentRoot[@@templateid = '$pressReleaseTemplateId']"
	Write-Host "Queries:`n  $queryDescendants`n  $querySelf" -ForegroundColor Cyan

	$pressReleaseRoots = @(
		@(Get-Item -Path master: -Language "*" -Query $queryDescendants -ErrorAction SilentlyContinue) +
		@(Get-Item -Path master: -Language "*" -Query $querySelf -ErrorAction SilentlyContinue)
	)
	if (-not $pressReleaseRoots -or $pressReleaseRoots.Count -eq 0) {
		Write-Host "No items found with Press Release template under $ContentRoot." -ForegroundColor Yellow
		return
	}

	$uniqueRoots = $pressReleaseRoots | Group-Object { $_.ID.ToString() } | ForEach-Object { $_.Group | Select-Object -First 1 }
	Write-Host "Found $($uniqueRoots.Count) Press Release page(s)." -ForegroundColor Green

	$totalItemsToWalk = 0
	foreach ($r in $uniqueRoots) {
		$countPath = "master:" + $r.Paths.Path
		$countDesc = @(Get-ChildItem -Path $countPath -Recurse)
		$totalItemsToWalk += 1 + $countDesc.Count
	}
	Write-Host "Total items to walk (all subtrees): $totalItemsToWalk" -ForegroundColor DarkGray

	$updated = 0
	$skippedNoField = 0
	$alreadyChecked = 0
	$itemsProcessed = 0
	$progressActivity = "Press release: set '$checkboxFieldName'"

	try {
		foreach ($root in $uniqueRoots) {
			$rootPath = "master:" + $root.Paths.Path
			$descendants = @(Get-ChildItem -Path $rootPath -Recurse)
			# Press Release page first, then all descendants (Get-ChildItem does not include the root item)
			$allInSubtree = @($root) + $descendants

			Write-Host "`nSubtree: $($root.Paths.Path) — Press Release page + $($descendants.Count) descendant(s) = $($allInSubtree.Count) item(s)" -ForegroundColor Magenta

			foreach ($node in $allInSubtree) {
				$itemsProcessed++
				$op = $node.Paths.Path
				if ($op.Length -gt 100) {
					$op = $op.Substring(0, 97) + "..."
				}
				$percent = if ($totalItemsToWalk -gt 0) {
					[math]::Min(100, [int][math]::Floor($itemsProcessed * 100.0 / $totalItemsToWalk))
				}
				else { 0 }
				Write-Progress -Activity $progressActivity -Status "Item $itemsProcessed of $totalItemsToWalk" -CurrentOperation $op -PercentComplete $percent -Id 1

				# Shared field: one update per item applies to all languages
				$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($node.TemplateID, $node.Database)
				if ($null -eq $template -or $null -eq $template.GetField($checkboxFieldName)) {
					$skippedNoField++
					continue
				}

				# Use Item field indexer — PowerShell cannot use Fields["name"] on FieldCollection
				if ($node[$checkboxFieldName] -eq "1") {
					$alreadyChecked++
					continue
				}

				$target = $node.Paths.Path
				if (-not $PSCmdlet.ShouldProcess($target, "Set shared checkbox '$checkboxFieldName' to checked")) {
					continue
				}

				$node.Editing.BeginEdit()
				try {
					$node[$checkboxFieldName] = "1"
					$node.Editing.EndEdit() | Out-Null
					$updated++
					Write-Host "  Checked: $target" -ForegroundColor DarkYellow
				}
				catch {
					$node.Editing.CancelEdit()
					Write-Error $_
				}
			}
		}

		Write-Host "`nDone. Updated: $updated; already checked: $alreadyChecked; no field on template (skipped): $skippedNoField" -ForegroundColor Cyan
	}
	finally {
		Write-Progress -Activity $progressActivity -Id 1 -Completed
	}
}

end {
	Write-Verbose "Set-PressReleaseCheckboxOnDescendants - End"
}
