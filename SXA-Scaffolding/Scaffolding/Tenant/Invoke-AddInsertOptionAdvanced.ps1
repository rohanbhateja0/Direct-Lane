function Invoke-AddInsertOptionAdvanced {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
        [Item]$ModuleDefinition,

	    [Parameter(Mandatory=$true, Position=1 )]
        [Item[]]$TenantTemplates
    )

	begin {
		Write-Verbose "Cmdlet Invoke-AddInsertOptionAdvanced - Begin"
		Import-Function Get-ProjectTemplateBasedOnBaseTemplate
		Import-Function Add-InsertOptionsToTemplate
	}

	process {
		Write-Verbose "Cmdlet Invoke-AddInsertOptionAdvanced - Process"
        [Sitecore.Data.Items.TemplateItem]$baseTemplate = Get-Item -Path master: -ID ($ModuleDefinition.Fields['Template'].Value)
        [Sitecore.Data.ID[]]$arguments = $ModuleDefinition.Fields['Arguments'].Value.Split('|')
        $template = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $baseTemplate.InnerItem.Template.InnerItem.ID
        if($template.Length -gt 1){ 
            $template = $template | Select-Object -First 1 
            Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
        }        
        if ($template) {
            Write-Verbose "Adding insert options to $($template.Paths.Path) : $($arguments)"
			$arguments | ForEach-Object {
				$tenantTemplate = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $_
				if($tenantTemplate){
					Add-InsertOptionsToTemplate $template $tenantTemplate.ID
				}
			}
        }
	}

	end {
		Write-Verbose "Cmdlet Invoke-AddInsertOptionAdvanced - End"
	}
}