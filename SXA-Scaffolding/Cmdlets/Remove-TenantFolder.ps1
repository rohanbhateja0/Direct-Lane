function Remove-TenantFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantFolder,
        [switch]$Force
    )

    begin {
        Write-Verbose "Cmdlet Remove-TenantFolder - Begin"
        Import-Function Remove-Tenant
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Remove-TenantFolder - Process"
        Write-Progress -Status "Removing '$($TenantFolder.Name)' tenant group" -Activity "Getting all tenants" -Completed
        $tenantItemTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseTenant]::ID.ToString()
        [Sitecore.Data.Items.Item[]]$tenants = $TenantFolder.Children | Select-InheritingFrom $tenantItemTemplateId | Wrap-Item

        $tenants | Where-Object { $_ -ne $null } | ForEach-Object { Remove-Tenant $_ -Force:$Force }

        $tenantFolderTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseTenantFolder]::ID.ToString()
        if ($TenantFolder.Children.Count -gt 0) {
            Write-Progress -Status "Removing '$($TenantFolder.Name)' tenant group" -Activity "Getting all other groups" -Completed
            [Sitecore.Data.Items.Item[]]$folders = $TenantFolder.Children | Select-InheritingFrom $tenantFolderTemplateId | Wrap-Item
            if ($folders) {
                $folders | ForEach-Object { Remove-TenantFolder $_ -Force:$Force }
            }
        }

        if ($TenantFolder.Children.Count -eq 0) {
            $oldestFolderParent = $TenantFolder
            while ([Sitecore.Data.Managers.TemplateManager]::GetTemplate($oldestFolderParent).InheritsFrom($tenantFolderTemplateId)) {
                $oldestFolderParent = $oldestFolderParent.Parent
            }

            $folderTail = $TenantFolder.Paths.Path.Replace($oldestFolderParent.Paths.Path, "")

            Write-Progress -Status "Removing '$($TenantFolder.Name)' tenant group" -Activity "Removing tenant templates folder" -Completed
            $tenantTemplatesFolderPath = "/sitecore/templates/Project/$folderTail"
            if (Test-Path $tenantTemplatesFolderPath) {
                $tenantFolderTemplateFolder = Get-Item -Path $tenantTemplatesFolderPath
                if ($tenantFolderTemplateFolder.Children.Count -eq 0) {
                    $tenantFolderTemplateFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove tenant templates folder '$($tenantTemplatesFolderPath)' as there are other folders/tenants inside"
                }
            }

            Write-Progress -Status "Removing '$($TenantFolder.Name)' tenant group" -Activity "Removing media library folder" -Completed
            $tenantMediaFolderPath = "/sitecore/media library/Project/$folderTail"
            if (Test-Path $tenantMediaFolderPath) {
                $tenantFolderMediaFolder = Get-Item -Path $tenantMediaFolderPath
                if ($tenantFolderMediaFolder.Children.Count -eq 0) {
                    $tenantFolderMediaFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove tenant media folder '$($tenantMediaFolderPath)' as there are other folders/tenants inside"
                }
            }

            Write-Progress -Status "Removing '$($TenantFolder.Name)' tenant group" -Activity "Removing themes folder" -Completed
            $themesFolderPath = "/sitecore/media library/Themes/$folderTail"
            if (Test-Path $themesFolderPath) {
                $themesFolder = Get-Item -Path $themesFolderPath
                if ($themesFolder.Children.Count -eq 0) {
                    $themesFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove themes folder '$($themesFolderPath)' as there are other folders/tenants inside"
                }
            }
            
            Write-Progress -Status "Removing '$($TenantFolder.Name)' tenant group" -Activity "Removing forms folder" -Completed
            $formsFolderPath = "/sitecore/Forms/$folderTail"
            if (Test-Path $formsFolderPath) {
                $formsFolder = Get-Item -Path $formsFolderPath
                if ($formsFolder.Children.Count -eq 0) {
                    $formsFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove forms folder '$($themesFolderPath)' as there are other folders/forms inside"
                }
            }
            
            Write-Progress -Status "Removing '$($TenantFolder.Name)' tenant group" -Activity "Removing renderings folder" -Completed
            $renderingsFolderPath = "/sitecore/layout/Renderings/Project/$folderTail"
            if (Test-Path $renderingsFolderPath) {
                $tenantFolderMediaFolder = Get-Item -Path $renderingsFolderPath
                if ($tenantFolderMediaFolder.Children.Count -eq 0) {
                    $tenantFolderMediaFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove tenant media folder '$($renderingsFolderPath)' as there are other folders/tenants inside"
                }
            }

            $TenantFolder.Recycle() > $null
        }
    }

    end {
        Write-Verbose "Cmdlet Remove-TenantFolder - End"
    }
}