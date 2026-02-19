function Get-SiteDefinitions {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$Layer
        )

	begin {
		Write-Verbose "Cmdlet Get-SiteDefinitions - Begin"
		Import-Function Select-SingleItemFromEachGroup
		Import-Function Get-ModuleDefinition
	}

	process {
		Write-Verbose "Cmdlet Get-SiteDefinitions - Process"
		Get-ModuleDefinition $Layer "SiteSetupRoot"
	}

	end {
		Write-Verbose "Cmdlet Get-SiteDefinitions - End"
	}
}