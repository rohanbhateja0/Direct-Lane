function Invoke-SiteAction {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true,ValueFromPipeline = $true,Position = 0)]
		[item]$site,

		[Parameter(Mandatory = $true,Position = 1)]
		[item]$ActionItem,

		[Parameter(Mandatory = $false,Position = 2)]
		[item]$SiteTheme,

		[Parameter(Mandatory = $false,Position = 3)]
		[item]$EditingTheme,
		
		[Parameter(Mandatory=$false, Position = 4 )]
		[string]$Language="en"		
	)

	begin {
		Write-Verbose "Cmdlet Invoke-SiteAction - Begin"
		Import-Function Invoke-AddInsertOptionsToItem
		Import-Function Get-TenantTemplate
		Import-Function Get-TenantItem
		Import-Function Invoke-AddItem
		Import-Function Invoke-EditTheme
		Import-Function Invoke-ExtendTheme
		Import-Function Invoke-ExecuteScript
	}

	process {
		Write-Verbose "Cmdlet Invoke-SiteAction - Process"
		$tenant = Get-TenantItem $site
		$tenantTemplatesRootID = $tenant.Fields['Templates'].Value
		$tenantTemplatesRoot = Get-Item -Path master: -Id $tenantTemplatesRootID
		$tenantTemplates = Get-TenantTemplate $tenantTemplatesRoot

		Write-Verbose "Invoking Site Action: $($ActionItem.Paths.Path)"
		switch ($ActionItem.TemplateName) {
			"EditSiteItem" {
				if ($ActionItem.EditType -eq "AddInsertOptions") {
					Invoke-AddInsertOptionsToItem $site $ActionItem
				}
			}
			"AddItem" {
				Invoke-AddItem $site $ActionItem $Language
			}
			"ExecuteScript" {
				Invoke-ExecuteScript $ActionItem $site $tenantTemplates
			}
			"EditEditingTheme" {
				if ($EditingTheme) {
					Invoke-EditTheme $EditingTheme $ActionItem
				}
			}
			"EditSiteTheme" {
				if ($SiteTheme) {
					Invoke-EditTheme $SiteTheme $ActionItem
				}
			}
			"ExtendSiteTheme" {
				if ($SiteTheme) {
					Invoke-ExtendTheme $SiteTheme $ActionItem
				}
			}

			Default {}
		}
	}

	end {
		Write-Verbose "Cmdlet Invoke-SiteAction - End"
	}
} 