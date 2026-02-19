function Get-TenantTemplateOrCreate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$TenantTemplates,


        [Parameter(Mandatory = $true, Position = 1 )]
        [Sitecore.Data.ID]$TemplateId
    )

    begin {
        Write-Verbose "Cmdlet Get-TenantTemplateOrCreate - Begin"
        Import-Function Get-ProjectTemplateBasedOnBaseTemplate
        Import-Function New-TenantTemplate
    }

    process {
        Write-Verbose "Cmdlet Get-TenantTemplateOrCreate - Process"
        $templateItem = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $TemplateId | Select-Object -First 1
        if (-not $templateItem) {
            $root = $TenantTemplates  | ? { $_.TemplateName -eq "Template" } | Sort-Object -property @{Expression={[int]$_.Paths.Path.Split('/').Count}} | Select-Object -First 1
            $root = $root.Parent
            $templateItem = New-TenantTemplate $root $TemplateId
        }
        $templateItem
    }

    end {
        Write-Verbose "Cmdlet Get-TenantTemplateOrCreate - End"
    }
}