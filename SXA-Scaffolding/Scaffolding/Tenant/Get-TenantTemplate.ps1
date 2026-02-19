function Get-TenantTemplate {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0 )]
        [Item]$TenantTemplatesRoot
	)

	begin {
		Write-Verbose "Cmdlet Get-TenantTemplate - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-TenantTemplate - Process"
		[Item[]]$tenantTemplates = Get-ChildItem -Path $TenantTemplatesRoot.Paths.Path -Recurse | ? { $_.TemplateName -eq "Template" }
		$tenantTemplates
	}
	end {
		Write-Verbose "Cmdlet Get-TenantTemplate - End"
	}
}