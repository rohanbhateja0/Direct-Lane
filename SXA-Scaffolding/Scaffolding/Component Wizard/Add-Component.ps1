function Add-Component {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Sitecore.XA.Foundation.Scaffolding.Models.ComponentWizardModel]$Model
    )

    begin {
        Write-Verbose "Cmdlet Add-Component - Begin"
        Import-Function Get-TemplatesFolderForFeature
        Import-Function Add-FolderStructure
        Import-Function Copy-Rendering
        Import-Function Get-SettingsFolderForFeature
        Import-Function Get-SiteSetupForModule
        Import-Function Add-SetupItemDependency
        Import-Function Get-BranchesFolderForFeature
        Import-Function Get-ModuleRootCandidate
    }

    process {
        Write-Verbose "Cmdlet Add-Component - Process"
        
        [Sitecore.Data.ID]$renderingOptionsSectionTemplateID = "{D1592226-3898-4CE2-B190-090FD5F84A4C}"
        if ($Model.RenderingTemplate -ne $null -and [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Model.RenderingTemplate.ID, $Model.RenderingTemplate.Database).InheritsFrom($renderingOptionsSectionTemplateID)) {
            $itemType = $Model.RenderingTemplate.Paths.Path
        }
        else {
            $itemType = "System/Layout/Renderings/Controller rendering"
        }
        
        $component = New-Item -Parent $Model.TargetModule -Name $Model.ComponentName -ItemType $itemType | Wrap-Item
        $Model.TargetModule = Get-ModuleRootCandidate $Model.TargetModule
        if ($Model.Class) {
            $component.RenderingCssClass = $Model.Class
        }
        
        [Sitecore.Data.ID]$controllerRenderingTemplateID = "{2A3E91A0-7987-44B5-AB34-35C2D9DE83B9}"
        if ([Sitecore.Data.Managers.TemplateManager]::GetTemplate($component.TemplateID, $component.Database).InheritsFrom($controllerRenderingTemplateID)) {
            if ($Model.Controller) {
                $component.Controller = $Model.Controller
            }
            else {
                if ($Model.ComponentsVariantsSupport) {
                    $component.Controller = "Sitecore.XA.Foundation.RenderingVariants.Controllers.VariantsController,Sitecore.XA.Foundation.RenderingVariants"
                }
                else {
                    $component.Controller = "Sitecore.XA.Foundation.Mvc.Controllers.StandardController,Sitecore.XA.Foundation.Mvc"
                }
            }
        }
        if ($Model.Action) {
            $component."Controller Action" = $Model.Action
        }
        if ($Model.View) {
            $component.RenderingViewPath = $Model.View
        }
        if ($Model.CanSelectPages) {
            $component."Can select Page as a data source" = $Model.CanSelectPages
        } 
        if ($Model.CompatibleTemplates) {
            $component."Additional compatible templates" = ($Model.CompatibleTemplates | % { $_.ID }) -join '|'
        }
        if ($Model.OtherProperties) {
            $component."OtherProperties" = ($model.OtherProperties | % { "$($_)=true" }) -join "&"
        }
        if ($Model.BaseRenderingParametersTemplates.Count -gt 0) {
            $renderingParametersItemName = $Model.ComponentName
            $templatesFolderForFeature = Get-TemplatesFolderForFeature $Model.TargetModule
            
            $renderingParametersFolder = Add-FolderStructure "$($templatesFolderForFeature.Paths.Path)/Rendering Parameters" "System/Templates/Template Folder"
            $newRenderingRenderingParameterTemplateItem = New-Item -ItemType "System/Templates/Template" -Parent $renderingParametersFolder -Name $renderingParametersItemName | Wrap-Item
            $newRenderingRenderingParameterTemplateItem."__Base template" = ($Model.BaseRenderingParametersTemplates.ID -join '|')
            
            $component."Parameters Template" = $newRenderingRenderingParameterTemplateItem.ID
        }
        if ($Model.BaseDataSourceTemplate -and $Model.DataSourceMode -ne [Sitecore.XA.Foundation.Scaffolding.Models.ComponentDataSourceMode]::CurrentPage) {
            $dataSourceItemName = $Model.ComponentName
            $templatesFolderForFeature = Get-TemplatesFolderForFeature $Model.TargetModule
            $dataSourceFolder = Add-FolderStructure "$($templatesFolderForFeature.Paths.Path)/Data Source" "System/Templates/Template Folder"
            
            $datasourceFolderTemplateItem = New-Item -ItemType "System/Templates/Template" -Parent $dataSourceFolder -Name $dataSourceItemName | Wrap-Item
            ($datasourceFolderTemplateItem -as [Sitecore.Data.Items.TemplateItem]).CreateStandardValues() > $null
            
            $component."Datasource Template" = $datasourceFolderTemplateItem.Paths.Path
            
            $baseDataSourceTemplates = @($Model.BaseDataSourceTemplate.ID)
            if ($model.BackgroundImageSupport) {
                $backgroundImageTemplateID = "{F09CFB6D-7E3D-4C65-8AA8-85281A59940E}"
                $baseDataSourceTemplates += $backgroundImageTemplateID
            }
            if ($model.CanSetDataSourceBehaviour) {
                $globalDatasourceBehaviorTemplateID = "{A7837DE9-3266-46CB-A945-62C55DA45E9E}"
                $baseDataSourceTemplates += $globalDatasourceBehaviorTemplateID
            }
            if ($model.HorizonDatasourceGrouping) {
                $baseDataSourceTemplates += "{D0F6BE14-2A2D-4C56-ACB5-80CAA573B8E2}"
            }
            if ($model.PublishingGroupingTemplates) {
                $baseDataSourceTemplates += "{8BA7DAC6-32ED-4378-BD9E-5DA5B0F9848D}"
            }            
            $datasourceFolderTemplateItem."__Base template" = $baseDataSourceTemplates -join "|"
        }
        
        # site setup + available renderings
        $settingsFolderForFeature = Get-SettingsFolderForFeature $Model.TargetModule
        $branhcesFolderForFeature = Get-BranchesFolderForFeature $Model.TargetModule
        $siteSetupItem = Get-SiteSetupForModule $settingsFolderForFeature
        $addAvailableRenderingsAddActionID = "{BDF83718-907A-435B-B1BA-64139E07983F}"
        Add-SetupItemDependency $siteSetupItem $addAvailableRenderingsAddActionID
        
        $virtualLocationIDAvailableRenderings = "{84179507-91A2-47EA-A424-9D338F64C953}"
        $availableRenderingsAction = Get-ChildItem -Path $siteSetupItem.Paths.Path -Recurse | ? { $_.TemplateName -eq "AddItem" } | ? { $_.Location -eq $virtualLocationIDAvailableRenderings } | Select-Object -First 1
        
        if ($availableRenderingsAction) {
            $branch = $model.TargetModule.Database.GetItem($availableRenderingsAction.Fields['Template'].Value)
            $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
        }
        else {
            $availableRenderingsAction = New-Item -ItemType "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem" -Path $siteSetupItem.Paths.Path -Name "Add Available Renderings" | Wrap-Item
            $availableRenderingsAction."Location" = $virtualLocationIDAvailableRenderings
            $availableRenderingsAction."__Name" = $Model.TargetModule.Name
            $TemplatesFolderForFeature = $branhcesFolderForFeature
            if ($TemplatesFolderForFeature -eq $null) {
                $TemplatesFolderForFeature = Get-TemplatesFolderForFeature $Model.TargetModule
            }
            $emptyAvailableRenderingsBranch = Get-Item -Path "/sitecore/templates/Branches/Foundation/Experience Accelerator/Scaffolding/Empty Available Renderings"
            $branch = $emptyAvailableRenderingsBranch.CopyTo($TemplatesFolderForFeature, "Available $($model.RenderingName) Renderings") | Wrap-Item
            $branch."__Display Name" = ""
            $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
            # $availableRenderingsItem.ChangeTemplate($availableRenedringsItemFromBranch.Template)
            $availableRenderingsAction."__Template" = $branch.ID
        }
        
        $availableRenderingsItem."Renderings" = ($availableRenderingsItem."Renderings", $component.ID | ? { $_ -ne "" }) -join "|"
        
        
        # ComponentsVariantsSupport
        if ($Model.ComponentsVariantsSupport -eq $true) {
            $newDefaultVariantName = 'Default ' + $model.ComponentName + ' Variant'
            $newDefaultVariantBranch = New-Item -ItemType "System/Branches/Branch" -Parent $branhcesFolderForFeature -Name $newDefaultVariantName | Wrap-Item
            New-Item -ItemType "Foundation/Experience Accelerator/Rendering Variants/Variants" -Parent $newDefaultVariantBranch -Name '$name' > $null
            
            # site ssetup add action
            $newRenderingSiteSetupAddRVFolderName = "Rendering Variants"
            $newRenderingSiteSetupAddRVFolderPath = $siteSetupItem.Paths.Path + "/" + $newRenderingSiteSetupAddRVFolderName
            if (Test-Path $newRenderingSiteSetupAddRVFolderPath) {
                $newRenderingSiteSetupAddRVFolder = Get-Item -Path $newRenderingSiteSetupAddRVFolderPath
            }
            # If it does not exist, create new one
            if ($newRenderingSiteSetupAddRVFolder -eq $null) {
                $newRenderingSiteSetupAddRVFolder = New-Item -ItemType "/sitecore/templates/Common/Folder" -Parent $siteSetupItem -Name $newRenderingSiteSetupAddRVFolderName
            }            
            $addRenderingVariantItem = New-Item -ItemType "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem" -Parent $newRenderingSiteSetupAddRVFolder -Name $Model.ComponentName | Wrap-Item
            
            #3. Change newly created AddItem Action Item fields (not standard one)
            $virtualLocationIDRenderingVariants = "{5CDC5EB2-F14F-4495-88E8-AA882DDFAA05}"
            $addRenderingVariantItem._Name = $Model.ComponentName
            $addRenderingVariantItem.Location = $virtualLocationIDRenderingVariants
            $addRenderingVariantItem._Template = $newDefaultVariantBranch.ID.ToString()
        }
        
        # View
        if ($Model.View.Length -eq 0 -and $itemType.EndsWith("Controller rendering")) {
            $componentName = $Model.ComponentName
            $viewsPath = Join-Path $AppPath "Views"
            
            if ($Model.ComponentsVariantsSupport) {
                $viewName = "ComponentWizard-VariantsRenderingModel.cshtml"
            }
            else {
                $viewName = "ComponentWizard-RenderingModelBase.cshtml"
            }   
            
            $baseViewPath = "$viewsPath/ComponentWizard/$viewName"            
            $newViewPath = $baseViewPath.Replace($viewName, "$componentName.cshtml").Replace("ComponentWizard",$componentName)
            
            if ($Model.Class -ne "") {
                $cssClass = $Model.Class
            }
            else {
                $cssClass = $componentName
            }
            
            if (Test-Path $newViewPath) {
                Write-Verbose "View already exist $newViewPath"
                # $newViewFile = Get-Item $newViewPath
            }
            else {
                if (Test-Path $baseViewPath) {
                    $baseViewFile = Get-Item $baseViewPath
                    
                    $folder = "$viewsPath/$componentName"
                    if ((Test-Path $folder) -eq $false) {
                        New-Item -ItemType Directory -Path $folder > $null
                    }
                    
                    $newViewFile = $baseViewFile.CopyTo($newViewPath)
                    $content = Get-Content $newViewPath
                    $content = $content.Replace("[COMPONENT_NAME]", $cssClass)
                    Set-Content -Value $content -LiteralPath $newViewPath > $null
                }                
            }
            $component.RenderingViewPath = $newViewPath.Replace($viewsPath, "~/Views")
        }
    }

    end {
        Write-Verbose "Cmdlet Add-Component - End"
    }
}