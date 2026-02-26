function Invoke-ModuleScriptBody {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$Tenant,

		[Parameter(Mandatory=$true, Position=1 )]
        [Item[]]$TenantTemplates		
    )

	begin {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Begin"
		Import-Function Get-ProjectTemplateBasedOnBaseTemplate
	}

	process {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Process"
		Write-Verbose "My tenant: $($Tenant.Paths.Path)"
		Write-Verbose "My tenant templates: $($TenantTemplates | %{$_.ID})"

        Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates ([Sitecore.XA.Foundation.Multisite.Templates+Home]::ID.ToString()) | % {
            $homeItem = $_
            Write-Verbose "Found home item ($($homeItem.Paths.Path)). Changing base template"        

            $pageItem = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates ([Sitecore.XA.Foundation.Multisite.Templates+Page]::ID.ToString())
            if($pageItem.Length -gt 1){ 
                $pageItem = $pageItem | Select-Object -First 1 
                Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
            }

            Write-Verbose "Found tenant page item ($($pageItem.Paths.Path))"        
            $oldValue = $homeItem.Fields['__Base template'].Value
            Write-Verbose "oldValue: $oldValue"
            $newValue = "$($pageItem.ID)", $oldValue -join "|"  
            Write-Verbose "newValue: $newValue"

            $homeItem.'__Base template' = $newValue            
        }
	}

	end {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - End"
	}
}