function Copy-Site {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [item]$Destination,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$CopyName,

        [Parameter(Mandatory = $false, Position = 3)]
        [System.Collections.Hashtable]$SiteDefinitionsMapping
    )

    begin {
        Write-Verbose "Cmdlet Copy-Site - Begin"
        Import-Function Get-SettingsItem
        Import-Function Get-SiteMediaItem
        Import-Function Copy-RootAndFixReference
        Import-Function Set-NewLinkReference
        Import-Function Set-SiteDefinitionName
        Import-Function Set-CreativeExchangeFileStorageReference
        Import-Function Add-FormsFolder
        Import-Function Get-TenantItem
        Import-Function Add-FolderStructure
        Import-Function Get-SiteDefinition
        Import-Function Set-POS
    }

    process {
        Write-Verbose "Cmdlet Copy-Site - Process"

        $destinationSite = Copy-RootAndFixReference $Site $Destination $CopyName | Wrap-Item

        if ($destinationSite) {
		    
            Set-CreativeExchangeFileStorageReference $destinationSite $CopyName
            $tenantItem = Get-TenantItem $destinationSite
            $siteTail = $DestinationSite.Parent.Paths.Path.Replace($tenantItem.Paths.Path, "").TrimStart("/")

            if ($Site.ThemesFolder) {
                $ThemesFolder = $Site.Database.GetItem($Site.ThemesFolder) | Wrap-Item
                $tenantThemes = $tenantItem.Database.GetItem($tenantItem[[Sitecore.XA.Foundation.Multisite.Templates+Tenant+Fields]::Themes])
                $folderPath = [System.IO.Path]::Combine($tenantThemes.Paths.Path, $siteTail).Replace("\", "/").Replace("//", "/")
                $destinationItem = Add-FolderStructure $folderPath
                $NewThemesFolder = Copy-RootAndFixReference $ThemesFolder $destinationItem $destinationSite.Name

                Set-NewLinkReference $Site $destinationSite $ThemesFolder.Paths.Path $NewThemesFolder.Paths.Path
                $destinationSite.ThemesFolder = $NewThemesFolder.ID
            }
            if ($Site.SiteMediaLibrary) {
                $SiteMediaLibrary = $Site.Database.GetItem($Site.SiteMediaLibrary) | Wrap-Item
                $tenantMedia = $tenantItem.Database.GetItem($tenantItem[[Sitecore.XA.Foundation.Multisite.Templates+_BaseTenant+Fields]::MediaLibrary])
                $folderPath = [System.IO.Path]::Combine($tenantMedia.Paths.Path, $siteTail).Replace("\", "/").Replace("//", "/")
                $destinationItem = Add-FolderStructure $folderPath
                $NewSiteMediaLibrary = Copy-RootAndFixReference $SiteMediaLibrary $destinationItem $destinationSite.Name

                Set-NewLinkReference $Site $destinationSite $SiteMediaLibrary.Paths.Path $NewSiteMediaLibrary.Paths.Path
                $destinationSite = $Site.Database.GetItem($destinationSite.ID) | Wrap-Item # need to refresh fields table after Set-NewLinkReference
                if($destinationSite.SitemapMediaItems){
                    if (Test-Path $destinationSite.SitemapMediaItems) {
                        $Site.Database.GetItem($destinationSite.SitemapMediaItems) | Remove-Item
                        $destinationSite.SitemapMediaItems = [string]::Empty
                    }
                }
            }
            if ($Site."FormsFolderLocation") {
                Add-FormsFolder $destinationSite
            }

            $siteSettingsItem = Get-SettingsItem $Site
            $destinationSiteSettingsItem = Get-SettingsItem $destinationSite
            
            $sd = Get-SiteDefinition $destinationSite
            if ($SiteDefinitionsMapping) {
                Set-SiteDefinitionName $destinationSite $SiteDefinitionsMapping $sd
            }
            
            Set-POS $sd
            
            if ($siteSettingsItem -and $destinationSiteSettingsItem) {
                Set-NewLinkReference $Site $destinationSite $siteSettingsItem.Paths.Path $destinationSiteSettingsItem.Paths.Path
            }
        }
        $destinationSite
    }

    end {
        Write-Verbose "Cmdlet Copy-Site - End"
    }
}