function Remove-SiteFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteFolder,
        [switch]$Force
    )

    begin {
        Write-Verbose "Cmdlet Remove-SiteFolder - Begin"
        Import-Function Remove-Site
        Import-Function Get-ItemByIdSafe
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Remove-SiteFolder - Process"
        Write-Progress -Status "Removing '$($SiteFolder.Name)' site group" -Activity "Getting all sites" -Completed
        $siteItemTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteRoot]::ID.ToString()
        [Sitecore.Data.Items.Item[]]$sites = $SiteFolder.Children | Select-InheritingFrom $siteItemTemplateId | Wrap-Item

        $sites | Where-Object { $_ -ne $null } | ForEach-Object { Remove-Site $_ -Force:$Force }

        if ($SiteFolder.Children.Count -gt 0) {
            Write-Progress -Status "Removing '$($SiteFolder.Name)' site group" -Activity "Getting all other folders" -Completed
            $siteFolderTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteFolder]::ID.ToString()
            [Sitecore.Data.Items.Item[]]$folders = $SiteFolder.Children | Select-InheritingFrom $siteFolderTemplateId | Wrap-Item
            $folders | ForEach-Object { Remove-SiteFolder $_ -Force:$Force }
        }

        if ($SiteFolder.Children.Count -eq 0) {
            $oldestFolderParent = $SiteFolder
            $siteFolderTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseTenant]::ID.ToString()
            while ([Sitecore.Data.Managers.TemplateManager]::GetTemplate($oldestFolderParent).InheritsFrom($siteFolderTemplateId) -eq $false) {
                $oldestFolderParent = $oldestFolderParent.Parent | Wrap-Item
            }

            $folderTail = $SiteFolder.Paths.Path.Replace($oldestFolderParent.Paths.Path, "")

            Write-Progress -Status "Removing '$($SiteFolder.Name)' site group" -Activity "Removing media library folder" -Completed
            $tenantMediaLibrary = Get-ItemByIdSafe $oldestFolderParent.MediaLibrary
            $tenantThemesFolder = Get-ItemByIdSafe $oldestFolderParent.Themes

            $siteMediaFolderPath = "$($tenantMediaLibrary.Paths.Path)/$folderTail"
            if (Test-Path $siteMediaFolderPath) {
                $SiteFolderMediaFolder = Get-Item -Path $siteMediaFolderPath
                if ($SiteFolderMediaFolder.Children.Count -eq 0) {
                    $SiteFolderMediaFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove site media folder '$($siteMediaFolderPath)' as there are other folders/sites inside"
                }
            }
      
            $siteThemesFolderPath = "$($tenantThemesFolder.Paths.Path)/$folderTail"
            if (Test-Path $siteThemesFolderPath) {
                $siteThemesFolder = Get-Item -Path $siteThemesFolderPath
                if ($siteThemesFolder.Children.Count -eq 0) {
                    $siteThemesFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove site media folder '$($siteThemesFolderPath)' as there are other folders/sites inside"
                }
            }
            $SiteFolder.Recycle() > $null
        }
    }

    end {
        Write-Verbose "Cmdlet Remove-SiteFolder - End"
    }
}