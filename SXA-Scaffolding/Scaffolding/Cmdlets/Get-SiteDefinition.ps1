function Get-SiteDefinition {
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$true, ValueFromPipeline = $true, Position=0 )]
		[Item]$Item
        )

	begin {
		Write-Verbose "Cmdlet Get-SiteDefinition - Begin"
        Import-Function Get-SettingsItem
        Import-Function Select-InheritingFrom
	}

	process {
		Write-Verbose "Cmdlet Get-SiteDefinition - Process"   
        $settingsItem = Get-SettingsItem $Item

        [Sitecore.Data.ID]$_baseSiteDefinition = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteDefinition]::ID
        [Sitecore.Data.ID]$_baseSiteGrouping = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteGrouping]::ID

        $sitesGroupingItem = $settingsItem.Children | Select-InheritingFrom $_baseSiteGrouping | Select-Object -First 1
        Get-ChildItem -Path $sitesGroupingItem.Paths.Path -Recurse | Select-InheritingFrom $_baseSiteDefinition  
	} 

	end {
		Write-Verbose "Cmdlet Get-SiteDefinition - End"
	}
}