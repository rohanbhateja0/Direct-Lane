function Test-ItemIsSiteDefinition {
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$true, ValueFromPipeline = $true, Position=0 )]
		[Item]$Item
        )

	begin {
		Write-Verbose "Cmdlet Test-ItemIsSiteDefinition - Begin"
	}

	process {
		Write-Verbose "Cmdlet Test-ItemIsSiteDefinition - Process"   
		[Sitecore.Data.ID]$SiteDefinitionTemplate = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteDefinition]::ID
        [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Item).InheritsFrom($SiteDefinitionTemplate)
	} 

	end {
		Write-Verbose "Cmdlet Test-ItemIsSiteDefinition - End"
	}
}