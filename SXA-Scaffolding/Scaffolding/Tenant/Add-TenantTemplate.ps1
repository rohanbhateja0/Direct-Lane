function Add-TenantTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantTemplateLocation,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Add-TenantTemplate - Begin"
        Import-Function Get-SourceTemplate
        Import-Function New-TenantTemplate
    }

    process {
        Write-Verbose "Cmdlet Add-TenantTemplate - Process"
        if (Test-Path -Path $TenantTemplateLocation.Paths.Path) {
            $sourceTemplates = Get-SourceTemplate $DefinitionItems

            foreach ($template in $sourceTemplates) {
                New-TenantTemplate $TenantTemplateLocation $template
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Add-TenantTemplate - End"
    }
}