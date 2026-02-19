function Add-InsertOptionsToItem {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0 )]
        [Item]$Item,
        
        [Parameter(Mandatory=$true, Position=1)]
        [Sitecore.Data.ID[]]$InsertOptions
        )

	begin {
		Write-Verbose "Cmdlet Add-InsertOptionsToItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Add-InsertOptionsToItem - Process"
		if ($Item."__Masters" -ne "") {
			[Sitecore.Data.ID[]]$existingInsertOptions = $Item."__Masters".Split('|') | ? { $_ -ne ""}
		}else {
			[Sitecore.Data.ID[]]$existingInsertOptions = New-Object  System.Collections.ArrayList
		}
		[Sitecore.Data.ID[]]$uniqueInsertOptions  = Compare-Object $existingInsertOptions $InsertOptions -IncludeEqual | ? { $_.SideIndicator -eq "=>" } | %{ $_.InputObject }
		$rawValue = $uniqueInsertOptions -join "|"

		$newValue = $Item.__Masters, $rawValue -join "|"
		$Item.__Masters = $newValue
	}

	end {
		Write-Verbose "Cmdlet Add-InsertOptionsToItem - End"
	}
}