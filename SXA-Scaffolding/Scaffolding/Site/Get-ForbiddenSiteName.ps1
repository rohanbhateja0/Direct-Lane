function Get-ForbiddenSiteName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$SiteLocation
    )

    begin {
        Write-Verbose "Cmdlet Get-ForbiddenSiteName - Begin"
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Get-ForbiddenSiteName - Process"
        $siteItemTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteRoot]::ID.ToString()
        $forbiddenSiteNames = [Sitecore.Sites.SiteManager]::GetSites() | % { $_.Name }
        $SiteLocation.Children | Select-InheritingFrom $siteItemTemplateId | % { $forbiddenSiteNames += $_.Name }
        $forbiddenSiteNames | Select-Object -Unique
    }

    end {
        Write-Verbose "Cmdlet Get-ForbiddenSiteName - End"
    }
}