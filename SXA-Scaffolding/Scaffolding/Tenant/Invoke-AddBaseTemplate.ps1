function Invoke-AddBaseTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$ModuleDefinition,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$TenantTemplates
    )

    begin {
        Write-Verbose "Cmdlet Invoke-AddBaseTemplate - Begin"        
        Import-Function Add-BaseTemplate
        Import-Function Get-TenantTemplateOrCreate
    }

    process {
        Write-Verbose "Cmdlet Invoke-AddBaseTemplate - Process"
        [Sitecore.Data.Items.TemplateItem]$baseTemplate = Get-Item -Path master: -ID ($ModuleDefinition.Fields['Template'].Value)
        [Sitecore.Data.Items.TemplateItem[]]$arguments = $ModuleDefinition.Fields['Arguments'].Value.Split('|') | % {Get-Item -Path master: -ID $_}        
        $template = Get-TenantTemplateOrCreate $TenantTemplates $baseTemplate.InnerItem.Template.InnerItem.ID
        if ($template) {
            $arguments | % {
                Write-Verbose "Adding base template to $($template.Paths.Path) : $($ModuleDefinition.Fields['Arguments'].Value)"
                Add-BaseTemplate $template $_
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Invoke-AddBaseTemplate - End"
    }
}