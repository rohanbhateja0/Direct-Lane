function Get-BaseTenantTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [Item]$tenantItem,
        [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true)]
        [ID]$baseTemplate
    )

    begin {
        Write-Verbose "Cmdlet Get-BaseTenantTemplate - Begin"
        Import-Function Get-AllSxaTenant
        Import-Function Get-TenantTemplatesRoot
        Import-Function Get-TenantTemplate
    }

    process {
        $templateRoot = Get-TenantTemplatesRoot $tenantItem
        $tenantTemplate = Get-TenantTemplate $templateRoot
        $tenantTemplate = $tenantTemplate | ? { 
            $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($_.ID, $_.Database)
            $template.InheritsFrom($baseTemplate)
        }
        $allBase = $tenantTemplate | % { $_.ID.ToString() }
        $tenantTemplate | ? {
            $ownTemplates = $_."__Base Template".Split("|") | ? { $allBase.Contains($_) -eq $true }
            $ownTemplates.Count -eq 0
        }
    }

    end {
        Write-Verbose "Cmdlet Get-BaseTenantTemplate - End"
    }
}