Import-Function Write-HostWithTimestamp

function Copy-CBRESite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [item]$Destination,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$CopyName,

        [Parameter(Mandatory = $false, Position = 3)]
        [System.Collections.Hashtable]$SiteDefinitionsMapping,

        [Parameter(Mandatory = $false, Position = 4)]
        [Item[]]$UseExistingThemes
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Copy-Site - Begin"
        Import-Function Get-SettingsItem
        Import-Function Get-SiteMediaItem
        Import-Function Copy-CBRERootAndFixReference
        Import-Function Set-CBRENewLinkReference
        Import-Function Set-SiteDefinitionName
        Import-Function Set-CreativeExchangeFileStorageReference
        Import-Function Add-FormsFolder
        Import-Function Get-TenantItem
        Import-Function Add-FolderStructure
        Import-Function Get-SiteDefinition
        Import-Function Set-POS
        Import-Function Get-ItemOrCreate
    }

    process {
        Write-HostWithTimestamp "Cmdlet Copy-Site - Process"
        Write-HostWithTimestamp "Copying site from: $($Site.Paths.Path) to: $($Destination.Paths.Path) with name: $CopyName"

        Write-HostWithTimestamp "Step 1: Copying root site item and fixing references..."
        $destinationSite = Copy-CBRERootAndFixReference $Site $Destination $CopyName | Wrap-Item
        Write-HostWithTimestamp "  - Destination site created at: $($destinationSite.Paths.Path)" -ForegroundColor Green

        if ($destinationSite) {
            Write-HostWithTimestamp "Step 2: Setting Creative Exchange file storage reference..."
            Set-CreativeExchangeFileStorageReference $destinationSite $CopyName
            Write-HostWithTimestamp "  - Creative Exchange file storage reference set" -ForegroundColor Green
            
            Write-HostWithTimestamp "Step 3: Getting tenant item..."
            $tenantItem = Get-TenantItem $destinationSite
            Write-HostWithTimestamp "  - Tenant item: $($tenantItem.Paths.Path)"
            $siteTail = $DestinationSite.Parent.Paths.Path.Replace($tenantItem.Paths.Path, "").TrimStart("/")
            Write-HostWithTimestamp "  - Site tail: $siteTail"

            if ($null -ne $UseExistingThemes) {
                # UseExistingThemes is provided (even if empty array) - skip cloning themes
                if ($UseExistingThemes.Count -gt 0) {
                    Write-HostWithTimestamp "Step 4: Using existing themes (skipping theme cloning)..." -ForegroundColor Cyan
                    Write-HostWithTimestamp "  - Using $($UseExistingThemes.Count) existing theme(s) instead of cloning"
                }
                else {
                    Write-HostWithTimestamp "Step 4: Skipping theme cloning (new theme will be created)..." -ForegroundColor Cyan
                }
                # Still need to create a themes folder for the site (for editing theme, etc.)
                $tenantThemes = $tenantItem.Database.GetItem($tenantItem[[Sitecore.XA.Foundation.Multisite.Templates+Tenant+Fields]::Themes])
                
                # Create a themes folder for the site if it doesn't exist
                $folderPath = [System.IO.Path]::Combine($tenantThemes.Paths.Path, $siteTail).Replace("\", "/").Replace("//", "/")
                Write-HostWithTimestamp "  - Creating destination themes folder structure: $folderPath"
                $destinationItem = Add-FolderStructure $folderPath
                
                # Check if folder already exists with site name
                $siteThemesFolderPath = [System.IO.Path]::Combine($folderPath, $destinationSite.Name).Replace("\", "/").Replace("//", "/")
                if (Test-Path "master:$siteThemesFolderPath") {
                    $NewThemesFolder = Get-Item -Path "master:$siteThemesFolderPath" | Wrap-Item
                    Write-HostWithTimestamp "  - Using existing themes folder at: $($NewThemesFolder.Paths.Path)" -ForegroundColor Green
                }
                else {
                    # Create empty themes folder for the site
                    $folderType = "/System/Media/Media folder"
                    $NewThemesFolder = Get-ItemOrCreate $destinationItem $destinationSite.Name $folderType
                    Write-HostWithTimestamp "  - Created themes folder at: $($NewThemesFolder.Paths.Path)" -ForegroundColor Green
                }
                
                $destinationSite.ThemesFolder = $NewThemesFolder.ID
                if ($UseExistingThemes.Count -gt 0) {
                    Write-HostWithTimestamp "  - Themes folder reference set (using existing themes)" -ForegroundColor Green
                }
                else {
                    Write-HostWithTimestamp "  - Themes folder reference set (ready for new theme creation)" -ForegroundColor Green
                }
            }
            elseif ($Site.ThemesFolder) {
                Write-HostWithTimestamp "Step 4: Copying themes folder..."
                $ThemesFolder = $Site.Database.GetItem($Site.ThemesFolder) | Wrap-Item
                Write-HostWithTimestamp "  - Source themes folder: $($ThemesFolder.Paths.Path)"
                $tenantThemes = $tenantItem.Database.GetItem($tenantItem[[Sitecore.XA.Foundation.Multisite.Templates+Tenant+Fields]::Themes])
                Write-HostWithTimestamp "  - Tenant themes folder: $($tenantThemes.Paths.Path)"
                $folderPath = [System.IO.Path]::Combine($tenantThemes.Paths.Path, $siteTail).Replace("\", "/").Replace("//", "/")
                Write-HostWithTimestamp "  - Creating destination folder structure: $folderPath"
                $destinationItem = Add-FolderStructure $folderPath
                Write-HostWithTimestamp "  - Copying themes folder to destination..."
                $NewThemesFolder = Copy-CBRERootAndFixReference $ThemesFolder $destinationItem $destinationSite.Name
                Write-HostWithTimestamp "  - New themes folder created at: $($NewThemesFolder.Paths.Path)" -ForegroundColor Green

                Write-HostWithTimestamp "  - Updating link references for themes folder..."
                Set-CBRENewLinkReference $Site $destinationSite $ThemesFolder.Paths.Path $NewThemesFolder.Paths.Path
                $destinationSite.ThemesFolder = $NewThemesFolder.ID
                Write-HostWithTimestamp "  - Themes folder reference updated" -ForegroundColor Green
            }
            else {
                Write-HostWithTimestamp "Step 4: Skipping themes folder (source site has no themes folder)" -ForegroundColor Yellow
            }
            
            if ($Site.SiteMediaLibrary) {
                Write-HostWithTimestamp "Step 5: Copying site media library..."
                $SiteMediaLibrary = $Site.Database.GetItem($Site.SiteMediaLibrary) | Wrap-Item
                Write-HostWithTimestamp "  - Source media library: $($SiteMediaLibrary.Paths.Path)"
                $tenantMedia = $tenantItem.Database.GetItem($tenantItem[[Sitecore.XA.Foundation.Multisite.Templates+_BaseTenant+Fields]::MediaLibrary])
                Write-HostWithTimestamp "  - Tenant media library: $($tenantMedia.Paths.Path)"
                $folderPath = [System.IO.Path]::Combine($tenantMedia.Paths.Path, $siteTail).Replace("\", "/").Replace("//", "/")
                Write-HostWithTimestamp "  - Creating destination folder structure: $folderPath"
                $destinationItem = Add-FolderStructure $folderPath
                Write-HostWithTimestamp "  - Copying media library to destination..."
                $NewSiteMediaLibrary = Copy-CBRERootAndFixReference $SiteMediaLibrary $destinationItem $destinationSite.Name
                Write-HostWithTimestamp "  - New media library created at: $($NewSiteMediaLibrary.Paths.Path)" -ForegroundColor Green

                Write-HostWithTimestamp "  - Updating link references for media library..."
                Set-CBRENewLinkReference $Site $destinationSite $SiteMediaLibrary.Paths.Path $NewSiteMediaLibrary.Paths.Path
                $destinationSite = $Site.Database.GetItem($destinationSite.ID) | Wrap-Item # need to refresh fields table after Set-CBRENewLinkReference
                Write-HostWithTimestamp "  - Media library link references updated" -ForegroundColor Green
                
                if($destinationSite.SitemapMediaItems){
                    Write-HostWithTimestamp "  - Checking sitemap media items..."
                    if (Test-Path $destinationSite.SitemapMediaItems) {
                        Write-HostWithTimestamp "  - Removing sitemap media items: $($destinationSite.SitemapMediaItems)"
                        $Site.Database.GetItem($destinationSite.SitemapMediaItems) | Remove-Item
                        $destinationSite.SitemapMediaItems = [string]::Empty
                        Write-HostWithTimestamp "  - Sitemap media items cleared" -ForegroundColor Green
                    }
                }
            }
            else {
                Write-HostWithTimestamp "Step 5: Skipping site media library (source site has no media library)" -ForegroundColor Yellow
            }
            
            if ($Site."FormsFolderLocation") {
                Write-HostWithTimestamp "Step 6: Adding forms folder..."
                Add-FormsFolder $destinationSite
                Write-HostWithTimestamp "  - Forms folder added" -ForegroundColor Green
            }
            else {
                Write-HostWithTimestamp "Step 6: Skipping forms folder (source site has no forms folder location)" -ForegroundColor Yellow
            }

            Write-HostWithTimestamp "Step 7: Getting settings items..."
            $siteSettingsItem = Get-SettingsItem $Site
            Write-HostWithTimestamp "  - Source site settings: $($siteSettingsItem.Paths.Path)"
            $destinationSiteSettingsItem = Get-SettingsItem $destinationSite
            Write-HostWithTimestamp "  - Destination site settings: $($destinationSiteSettingsItem.Paths.Path)"
            
            Write-HostWithTimestamp "Step 8: Getting site definition..."
            $sd = Get-SiteDefinition $destinationSite
            Write-HostWithTimestamp "  - Site definition found: $($sd.Count) item(s)"
            
            if ($SiteDefinitionsMapping) {
                Write-HostWithTimestamp "Step 9: Setting site definition names using mapping..."
                Write-HostWithTimestamp "  - Mapping $($SiteDefinitionsMapping.Count) site definition(s)"
                Set-SiteDefinitionName $destinationSite $SiteDefinitionsMapping $sd
                Write-HostWithTimestamp "  - Site definition names updated" -ForegroundColor Green
            }
            else {
                Write-HostWithTimestamp "Step 9: Skipping site definition name mapping (no mapping provided)" -ForegroundColor Yellow
            }
            
            Write-HostWithTimestamp "Step 10: Setting POS (Point of Sale) fields..."
            Set-POS $sd
            Write-HostWithTimestamp "  - POS fields set" -ForegroundColor Green
            
            if ($siteSettingsItem -and $destinationSiteSettingsItem) {
                Write-HostWithTimestamp "Step 11: Updating link references for settings items..."
                Set-CBRENewLinkReference $Site $destinationSite $siteSettingsItem.Paths.Path $destinationSiteSettingsItem.Paths.Path
                Write-HostWithTimestamp "  - Settings items link references updated" -ForegroundColor Green
            }
            else {
                Write-HostWithTimestamp "Step 11: Skipping settings link references (settings items not found)" -ForegroundColor Yellow
            }
            
            Write-HostWithTimestamp "Site copy completed successfully!" -ForegroundColor Green
        }
        else {
            Write-HostWithTimestamp "Failed to create destination site" -ForegroundColor Red
        }
        $destinationSite
    }

    end {
        Write-HostWithTimestamp "Cmdlet Copy-Site - End"
    }
}