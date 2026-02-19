function New-TenantTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantTemplateLocation,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Sitecore.Data.ID]$BaseTempalteID
    )

    begin {
        Write-Verbose "Cmdlet New-TenantTemplate - Begin"
        Import-Function Add-BaseTemplate
    }

    process {
        Write-Verbose "Cmdlet New-TenantTemplate - Process"
        $sourceTemplate = Get-Item -Path master: -ID $BaseTempalteID
        if ($sourceTemplate) {
            $newTemplate = New-Item -Parent $TenantTemplateLocation -Name $sourceTemplate.Name -ItemType "System/Templates/Template"
            Add-BaseTemplate $newTemplate $sourceTemplate > $null

            # Clone Field values
            $newTemplate.__Icon = $sourceTemplate.__Icon

            Write-Verbose "Created: $($newTemplate.Paths.Path)"
            if (-not $newTemplate.StandardValues) {
                ($newTemplate -as [Sitecore.Data.Items.TemplateItem]).CreateStandardValues() > $null
            }
            $newTemplate
        }
    }

    end {
        Write-Verbose "Cmdlet New-TenantTemplate - End"
    }
}