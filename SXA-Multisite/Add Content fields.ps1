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

        $pageTemplateItem = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates ([Sitecore.XA.Foundation.Multisite.Templates+Page]::ID.ToString())
        if($pageTemplateItem.Length -gt 1){ 
            $pageTemplateItem = $pageTemplateItem | Select-Object -First 1 
            Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
        }
        
        if ($pageTemplateItem) {
            Write-Verbose "Found page template item ($($homeItem.Paths.Path)). Changing base template"        
  
            $fieldSection = New-Item -Parent $pageTemplateItem -Name "Content" -ItemType "/sitecore/templates/System/Templates/Template section"
            
            $Title = New-Item -Parent $fieldSection -Name "Title" -ItemType "/sitecore/templates/System/Templates/Template field"
            $Title.Type = 'Single-Line Text'
            $Title.__Sortorder = 0

            $Content = New-Item -Parent $fieldSection -Name "Content" -ItemType "/sitecore/templates/System/Templates/Template field"
            $Content.Type = 'Rich Text'
            $Content.__Sortorder = 1
            $Content._Source = "query:`$xaRichTextProfile"

            $pageTemplateItem.Children | ?{ $_.Name -eq "__Standard Values" } | %{ 
                $svItem = (Get-Item -Path $_.Paths.Path)
                $fieldItem = $svItem.Fields['Title']
                if($fieldItem){
                    $svItem.'Title' = "`$name" 
                }
            }
        }
	}

	end {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - End"
	}
}