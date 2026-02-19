function Add-SiteMediaLibrary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site
    )

    begin {
        Write-Verbose "Cmdlet Add-SiteMediaLibrary - Begin"
        Import-Function Get-TenantItem
        Import-Function Get-TenantMediaLibraryRoot
        Import-Function Add-FolderStructure
    }

    process {
        $tenantItem = Get-TenantItem $Site
        $TenantMediaLibraryRoot = Get-TenantMediaLibraryRoot $site
        $siteTail = $Site.Paths.Path.Replace($tenantItem.Paths.Path, "")
        $path = $TenantMediaLibraryRoot.Paths.Path + $siteTail
        Add-FolderStructure $path
    }

    end {
        Write-Verbose "Cmdlet Add-SiteMediaLibrary - End"
    }
}