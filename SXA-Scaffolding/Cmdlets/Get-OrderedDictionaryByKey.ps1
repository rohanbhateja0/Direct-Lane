function Get-OrderedDictionaryByKey {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0 )]
        [System.Collections.Specialized.OrderedDictionary]$dictionary
	)

	begin {
		Write-Verbose "Cmdlet Get-OrderedDictionaryByKey - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-OrderedDictionaryByKey - Process"
        $temp = New-Object System.Collections.Specialized.OrderedDictionary
        $dictionary.GetEnumerator() | sort key | % { $temp.Add($_.key,$_.value) }
        $temp        
	}
	end {
		Write-Verbose "Cmdlet Get-OrderedDictionaryByKey - End"
	}
}