function Set-TenantTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Root,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$TenantTemplates
    )

    begin {
        Write-Verbose "Cmdlet Set-TenantTemplate - Begin"
        Import-Function Get-ProjectTemplateBasedOnBaseTemplate
    }

    process {
        Write-Verbose "Cmdlet Set-TenantTemplate - Process"
        $items = Get-ChildItem -Path $Root.Paths.Path -Recurse -WithParent -Language $Root.Language
        $items | % {
            Write-Verbose "Processing: $($_.Paths.Path)[$($_.ID)]"
            [Sitecore.Data.ID[]]$tenantTemplatesIDs = $TenantTemplates.ID
            if ($tenantTemplatesIDs.Contains($_.TemplateID) -eq $false) {
                $template = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $_.Template.InnerItem.ID | Wrap-Item
                if ($template.Length -gt 1) { 
                    $template = $template | Select-Object -First 1 
                    Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
                }
                if ($template) {
                    Write-Verbose "Found Tenant Template: $($template.Paths.Path)"
                    $_.ChangeTemplate($template)
                }
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Set-TenantTemplate - End"
    }
}