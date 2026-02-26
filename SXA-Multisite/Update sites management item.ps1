function Invoke-ModuleScriptBody {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true,Position = 0)]
		[item]$Site,

		[Parameter(Mandatory = $true,Position = 1)]
		[item[]]$TenantTemplates
	)

	begin {
		Import-Function Get-SettingsItem
		Import-Function Test-ItemIsSiteDefinition
		Import-Function Get-SxaSiteManagementItem

		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Begin"
	}

	process {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Process"
		Write-Verbose "My site: $($Site.Paths.Path)"
		Write-Verbose "My tenant templates: $($TenantTemplates | %{$_.ID})"

		$settingsItem = Get-SettingsItem $Site
		$siteDefinitionItem = Get-ChildItem -Recurse -Path ($settingsItem.Paths.Path) | ? { (Test-ItemIsSiteDefinition $_) -eq $true } | Select-Object -First 1
		$siteDefinitionItemId = $siteDefinitionItem.ID
		Write-Verbose "SXA site definition item: $($siteDefinitionItem.Paths.Path)"

		$siteManagementItem = Get-SxaSiteManagementItem
		Write-Verbose "SXA site management item: $($siteManagementItem.Paths.Path)"
		$option = [System.StringSplitOptions]::RemoveEmptyEntries
		$sitesList = $siteManagementItem.Order.Split('|',$option)
		$sitesList = $sitesList + @( $siteDefinitionItemId )
		$siteManagementItem.Order = $sitesList -join '|'
	}

	end {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - End"
	}
} 