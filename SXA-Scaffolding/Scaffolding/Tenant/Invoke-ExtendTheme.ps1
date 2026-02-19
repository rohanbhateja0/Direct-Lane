function Invoke-ExtendTheme {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true,Position = 0)]
		[item]$ThemeItem,

		[Parameter(Mandatory = $true,Position = 1)]
		[item]$ModuleDefinition
	)

	begin {
		Write-Verbose "Cmdlet Invoke-ExtendTheme - Begin"
	}

	process {
		Write-Verbose "Cmdlet Invoke-ExtendTheme - Process"
		$themeItemPath = $ThemeItem.Paths.Path
		[Sitecore.Data.ID[]]$arguments = $ModuleDefinition.Fields['Arguments'].Value.Split('|',[System.StringSplitOptions]::RemoveEmptyEntries)
		foreach ($themeId in $arguments) {
			$extensionTheme = Get-Item master: -Id $themeId
			$extensionThemePath = $extensionTheme.Paths.Path
			if ($extensionTheme) {
				$items = gci $extensionThemePath -Recurse
				foreach ($item in $items) {
					$path = $item.Paths.Path
					$destinationPath = $path.Replace($extensionThemePath,$themeItemPath)
					if (Test-Path $destinationPath) {
						if ($item.TemplateID -ne [Sitecore.TemplateIDs]::MediaFolder) {
							$destinationPath = "$destinationPath Copied from $($extensionTheme.Name)"
							Copy-Item -Path $path -Destination $destinationPath
						}
					} else {
						Copy-Item -Path $path -Destination $destinationPath
					}

				}
			}
		}
	}

	end {
		Write-Verbose "Cmdlet Invoke-ExtendTheme - End"
	}
}