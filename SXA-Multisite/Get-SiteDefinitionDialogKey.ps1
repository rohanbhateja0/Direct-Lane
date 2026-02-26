function Get-SiteDefinitionDialogKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$siteDefinitionName
    )

    begin {
        Write-Verbose "Cmdlet Get-SiteDefinitionDialogKey - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-SiteDefinitionDialogKey - Process"
        "_site_$($siteDefinitionName)"
    }

    end {
        Write-Verbose "Cmdlet Get-SiteDefinitionDialogKey - End"
    }
}