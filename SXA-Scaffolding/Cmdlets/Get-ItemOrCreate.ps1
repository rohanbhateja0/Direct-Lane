function Get-ItemOrCreate {
    [CmdletBinding()]
    param(
		[Parameter(Mandatory=$true, Position=0 )]
		[Item]$parent,
		[Parameter(Mandatory=$true, Position=1 )]
		[string]$itemName,
		[Parameter(Mandatory=$true, Position=2 )]
		[string]$itemType,
		[Parameter(Mandatory=$false, Position=3 )]
		[string]$language = "en"
        )

	begin {
		Write-Verbose "Cmdlet Get-ItemOrCreate - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-ItemOrCreate - Process"
		$exist = Test-Path "$($parent.Paths.Path)/$itemName"
		if(-not($exist)){
		    $item = New-Item -Parent $parent -Name $itemName -ItemType $itemType -Language $language
		} else {
		    $item = Get-Item -Path "master:$($parent.Paths.Path)/$itemName"
		}
        $item
	}

	end {
		Write-Verbose "Cmdlet Get-ItemOrCreate - End"
	}
}
