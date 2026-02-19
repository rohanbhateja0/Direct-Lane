function Get-TenantTemplatesRoot {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0 )]
        [Item]$ContextItem
	)

	begin {
		Write-Verbose "Cmdlet Get-TenantTemplatesRoot - Begin"
		Import-Function Get-TenantItem
		Import-Function Get-ItemByIdSafe
	}

	process {
		Write-Verbose "Cmdlet Get-TenantTemplatesRoot - Process"
		$tenantItem = Get-TenantItem $ContextItem

		Get-ItemByIdSafe $tenantItem.Templates
	}
	end {
		Write-Verbose "Cmdlet Get-TenantTemplatesRoot - End"
	}
}