function Get-ProjectTemplateBasedOnBaseTemplate {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
        [Item[]]$TenantTemplates,

	    [Parameter(Mandatory=$true, Position=1 )]
        [Sitecore.Data.ID]$ID
    )

	begin {
		Write-Verbose "Cmdlet Get-ProjectTemplateBasedOnBaseTemplate - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-ProjectTemplateBasedOnBaseTemplate - Process"
		$TenantTemplates | ? { $_.Fields['__Base template'].Value.Contains($ID) }
	}

	end {
		Write-Verbose "Cmdlet Get-ProjectTemplateBasedOnBaseTemplate - End"
	}
}