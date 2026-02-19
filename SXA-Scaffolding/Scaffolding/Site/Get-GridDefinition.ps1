Import-Function Select-SingleItemFromEachGroup

function Get-GridDefinition {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$Layer
        )

	begin {
		Write-Verbose "Cmdlet Get-GridDefinition - Begin"
		Import-Function Get-UniqueItem
	}

	process {
		Write-Verbose "Cmdlet Get-GridDefinition - Process"
        $query = "/sitecore/system/Settings/$Layer//*[@@templatename='Grid Setup']"
		$definitions = Get-Item -Path master: -Language "*" -Query $query
        Get-UniqueItem $definitions
	}

	end {
		Write-Verbose "Cmdlet Get-GridDefinition - End"
	}
}