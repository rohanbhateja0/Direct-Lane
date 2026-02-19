function Remove-Tenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantItem,
        [switch]$Force
    )

    begin {
        Write-Verbose "Cmdlet Remove-Tenant - Begin"
        Import-Function Remove-Site
        Import-Function Remove-SiteFolder
        Import-Function Get-ItemByIdSafe
        Import-Function Get-Modules
        Import-Function Invoke-PostDeleteStep
        Import-Function Invoke-PreDeleteStep
        Import-Function Test-HasPostDeleteStep
        Import-Function Test-HasPreDeleteStep
        Import-Function Invoke-PreDeleteValidationStep
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Remove-Tenant - Process"

        $tenantModules = Get-Modules $TenantItem | % { $_.InnerItem }
        Write-Verbose "Force: $Force"
        if ($Force) {
            $canRemove = $true
        }
        else {
            $canRemove = Invoke-PreDeleteValidationStep $tenantModules $TenantItem
        }
        if ($canRemove -eq $true) {
            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Getting tenant root item" -Completed
            $siteItemTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteRoot]::ID.ToString()
            $siteFolderTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteFolder]::ID.ToString()

            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Getting all sites" -Completed
            [Sitecore.Data.Items.Item[]]$sites = $TenantItem.Children | Select-InheritingFrom $siteItemTemplateId | Wrap-Item
            $sites | Where-Object { $_ -ne $null } | % { Remove-Site $_ -Force:$Force }
        
            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Getting all site folders" -Completed
            [Sitecore.Data.Items.Item[]]$siteFolders = $TenantItem.Children | Select-InheritingFrom $siteFolderTemplateId | Wrap-Item
            $siteFolders | Where-Object { $_ -ne $null } | % { Remove-SiteFolder $_ }

            $tenantTemplatesRoot = Get-ItemByIdSafe $TenantItem.Templates
            $tenantMediaLibrary = Get-ItemByIdSafe $TenantItem.MediaLibrary
            $tenantThemesFolder = Get-ItemByIdSafe $TenantItem.Themes
            $formsFolderLocation = Get-ItemByIdSafe $TenantItem.FormsFolderLocation

            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Removing tenant item" -Completed
            $preSetupStepModules = $tenantModules | ? { Test-HasPreDeleteStep $_ }
            $postSetupStepModules = $tenantModules | ? { Test-HasPostDeleteStep $_ }
            if ($preSetupStepModules) {
                Invoke-PreDeleteStep $preSetupStepModules $TenantItem
            }
            $TenantItem.Recycle() > $null

            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Removing tenant templates" -Completed
            Remove-TenantTemplates $tenantTemplatesRoot

            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Removing tenant media library" -Completed
            if ($tenantMediaLibrary) {
                if ($tenantMediaLibrary.Children.Count -eq 0 -or ($tenantMediaLibrary.Children.Count -eq 1 -and $tenantMediaLibrary.Children[0].Name -eq "shared")) {
                    $tenantMediaLibrary.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove tenant media library '$($item.Paths.Path)' as there are other folders/items inside"
                }
            }
        
            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Removing tenant themes folder" -Completed
            if ($tenantThemesFolder) {
                if ($tenantThemesFolder.Children.Count -eq 0) {
                    $tenantThemesFolder.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove tenant themes folder '$($item.Paths.Path)' as there are other folders/items inside"
                }
            }
        
            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Removing tenant forms folder" -Completed
            if ($formsFolderLocation) {
                if ($formsFolderLocation.Children.Count -eq 0) {
                    $formsFolderLocation.Recycle() > $null
                }
                else {
                    Write-Error "Could not remove tenant forms folder '$($item.Paths.Path)' as there are other folders/items inside"
                }   
            }     
        
            if ($postSetupStepModules) {
                Invoke-PostDeleteStep $postSetupStepModules $TenantItem
            }            
            Write-Progress -Status "Removing '$($TenantItem.Name)' tenant" -Activity "Done" -Completed
        }
    }

    end {
        Write-Verbose "Cmdlet Remove-Tenant - End"
    }
}

function Test-NoneItemIsUsingTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TemplateItem
    )

    begin {
        Write-Verbose "Cmdlet Test-NoneItemIsUsingTemplate - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-NoneItemIsUsingTemplate - Process"
        $templateId = $templateItem.ID
        $query = "/sitecore/content//*[@@templateid = '$templateId']"
        $items = Get-Item -Path master: -Language "*" -Query $query
        if ($items) {
            $false
        }
        else {
            $true
        }
    }

    end {
        Write-Verbose "Cmdlet Test-NoneItemIsUsingTemplate - End"
    }
}

function Remove-TenantTemplates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantTemplatesRoot
    )

    begin {
        Write-Verbose "Cmdlet Remove-TenantTemplates - Begin"
    }

    process {
        Write-Verbose "Cmdlet Remove-TenantTemplates - Process"
        $path = $TenantTemplatesRoot.Database.Name + ":" + $TenantTemplatesRoot.Paths.Path
        $tenantTemplates = Get-ChildItem -Path $path -Recurse | ? { $_.TemplateName -eq 'Template' }
        $canRemoveRoot = $true
        $tenantTemplates | Where-Object {
            $template = $_
            $notUsed = Test-NoneItemIsUsingTemplate $template
            if ($notUsed) {
                $template.Recycle() > $null
            }
            else {
                Write-Host "Could not remove template item as it is being used by at least one item" -ForegroundColor Cyan
                $canRemoveRoot = $false
            }
        }
        if ($canRemoveRoot) {
            $TenantTemplatesRoot.Recycle() > $null
        }
    }

    end {
        Write-Verbose "Cmdlet Remove-TenantTemplates - End"
    }
}