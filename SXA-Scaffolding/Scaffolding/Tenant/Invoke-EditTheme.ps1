function Invoke-EditTheme {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
        [Item]$ThemeItem,

	    [Parameter(Mandatory=$true, Position=1 )]
        [Item]$ModuleDefinition
    )

	begin {
		Write-Verbose "Cmdlet Invoke-EditTheme - Begin"
	}

	process {
		Write-Verbose "Cmdlet Invoke-EditTheme - Process"
        [Sitecore.Data.ID[]]$arguments = $ModuleDefinition.Fields['Arguments'].Value.Split('|')

		if ($ThemeItem.BaseLayout -ne "") {
			[Sitecore.Data.ID[]]$existingInsertOptions = $ThemeItem.BaseLayout.Split('|') | ? { $_ -ne ""}
		}else {
			[Sitecore.Data.ID[]]$existingInsertOptions = New-Object  System.Collections.ArrayList
		}
		[Sitecore.Data.ID[]]$uniqueInsertOptions  = Compare-Object $existingInsertOptions $arguments -IncludeEqual | ? { $_.SideIndicator -eq "=>" } | %{ $_.InputObject }

		$mergedIDs = $existingInsertOptions + $uniqueInsertOptions
		$ThemeItem.BaseLayout = $mergedIDs -join '|'
	}

	end {
		Write-Verbose "Cmdlet Invoke-EditTheme - End"
	}
}