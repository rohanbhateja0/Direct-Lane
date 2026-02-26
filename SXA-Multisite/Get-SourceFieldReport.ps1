function Get-SourceFieldReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0 )]
        [string]$StartPath = "/sitecore/templates/Project"
    )

    begin {
        Write-Verbose "Cmdlet Get-SourceFieldReport - Begin"        
        Import-Function Get-FieldSourceMapping
        Import-Function Get-FieldWithEmptySourceField
    }

    process {
        Write-Verbose "Cmdlet Get-SourceFieldReport - Process"

        $mapping = Get-FieldSourceMapping
        Get-FieldWithEmptySourceField $StartPath | Show-ListView `
            -ViewName "SxaReportView" `
            -ActionData $StartPath `
            -Property `
                @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Name); Expression = {$_.Name} },
                @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Path); Expression = {$_.Paths.Path } },
                @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Type); Expression = {$_.Fields["Type"].Value} },
                @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Recommendation); Expression = {$mapping[$_.Fields["Type"].Value]} }
    }
    end {
        Write-Verbose "Cmdlet Get-SourceFieldReport - End"
    }
}