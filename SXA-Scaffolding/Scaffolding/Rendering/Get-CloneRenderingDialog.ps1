function Get-CloneRenderingDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentRendering
    )

    begin {
        Write-Verbose "Cmdlet Get-CloneRenderingDialog - Begin"
        Import-Function Get-RenderingViewPath
        Import-Function Test-IsHeadlessRendering
    }

    process {
        Write-Verbose "Cmdlet Get-CloneRenderingDialog - Process"
        $name = $CurrentRendering.Name
        $renderingClass = $CurrentRendering.RenderingCssClass
        # todo folder nesting for target module (current parent)
        $defaultTargeModule = $CurrentRendering.Parent

        $renderingParametersSelection = [ordered]@{
            ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InheritFromExistingRenderingParameters)) = [Sitecore.XA.Foundation.Scaffolding.Models.RenderingParametersMode]::Inherit;
            ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::MakeCopyOfOriginalRenderingParameters)) = [Sitecore.XA.Foundation.Scaffolding.Models.RenderingParametersMode]::Copy
        };
        $datasourcesSelection = [ordered]@{
            ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InheritFromExistingDatasource)) = [Sitecore.XA.Foundation.Scaffolding.Models.DatasourceMode]::Inherit;
            ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::MakeCopyOfOriginalDatasource)) = [Sitecore.XA.Foundation.Scaffolding.Models.DatasourceMode]::Copy
        };

        $dialogParmeters = @()
        $dialogParmeters += @{ Name = "newRenderingName"; Value = "Copy of $name"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewRenderingName)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General))}
        $dialogParmeters += @{ Name = "targetModule"; Value = $defaultTargeModule; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FeatureToPutThisRenderingIn)); Root = "/sitecore/layout/Renderings/Feature"; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General))}
        $dialogParmeters += @{ Name = "newRenderingClass"; Value = "$renderingClass"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::RenderingCssClass)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General))}
        $dialogParmeters += @{ Name = "renderingParametersMode"; Value = "1"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::RenderingParameters)); Options = $renderingParametersSelection; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Parameters))}
        $dialogParmeters += @{ Name = "datasourcesMode"; Value = "1"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); Options = $datasourcesSelection; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource))}
        
        $renderingType = switch ($CurrentRendering.Template.Name)
        {
            "Json Rendering" {[Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::JsonRendering; Break}
            "JavaScript Rendering" {[Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::JavaScriptRendering; Break}
            "Controller rendering" {[Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::ControllerRendering; Break}
            Default {
                [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::Other
            }
        }
        
        if (-Not (Test-IsHeadlessRendering($renderingType))) {
          $viewPath = Get-RenderingViewPath $CurrentRendering
          $viewSelection = [ordered]@{
            ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::UseOriginalMvcViewFile)) = [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::UseExisting;
            ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CopyMvcViewFile)) = [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::Copy;
            ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SelectExistingMvcViewFile)) = [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::Select
          };
          $dialogParmeters += @{ Name = "viewMode"; Value = "1"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::View)); Options = $viewSelection; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::View))}
          $dialogParmeters += @{ Name = "newRenderingView"; Value = "$viewPath"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PathToRenderingView)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::View)) }
        }
        
        $result = Read-Variable -Parameters $dialogParmeters `
            -Description ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThisWizardEnablesYouToCreateDerivativeCopyOfRendering)) `
            -Title ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreateDerivativeRendering)) -Width 650 -Height 700 -OkButtonName "Proceed" -CancelButtonName "Abort" -ShowHints `
            -Validator {
            if ($variables.newRenderingName.Value.Length -eq 0) {
                $variables.newRenderingName.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorMissingRenderingName))
                continue
            }

            Import-Function Get-SettingsFolderForFeature
            $settingsFolder = Get-SettingsFolderForFeature $variables.targetModule.Value
            if ($settingsFolder -eq $null) {
                $variables.targetModule.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorFeaturePathDoesNotExist)) + "(Settings)"
                continue
            }
            $Rendering = $variables.targetModule.Value.Database.GetItem($RenderingID) | Wrap-Item
            if ($Rendering."Datasource Template") {
                Import-Function Get-TemplatesFolderForFeature
                $templatesFolder = Get-TemplatesFolderForFeature $variables.targetModule.Value
                if ($templatesFolder -eq $null) {
                    $variables.targetModule.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorFeaturePathDoesNotExist)) + "(Templates)"
                    continue
                }   
                $templateItem = $Rendering.Database.GetItem($Rendering."Datasource Template")
                if ($templateItem) {
                    if ($templateItem.TemplateName -eq "Branch") {
                        Import-Function Get-BranchesFolderForFeature
                        $branchesFolder = Get-BranchesFolderForFeature $variables.targetModule.Value
                        if ($branchesFolder -eq $null) {
                            $variables.targetModule.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorFeaturePathDoesNotExist)) + "(Braches)"
                            continue
                        }       
                    }
                }
            }
            else {
                if ($Rendering."Parameters Template") {
                    Import-Function Get-TemplatesFolderForFeature
                    $templatesFolder = Get-TemplatesFolderForFeature $variables.targetModule.Value
                    if ($templatesFolder -eq $null) {
                        $variables.targetModule.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorFeaturePathDoesNotExist)) + "(Templates)"
                        continue
                    }   
                }
            } 

            if ($variables.newRenderingView.Value.Length -eq 0 -and $variables.viewMode.Value -ne [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::UseExisting) {
                $variables.newRenderingView.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorInvalidViewPath))
                continue
            }
            
            $fullPath = (Join-Path $AppPath $variables.newRenderingView.Value.TrimStart("~"))
            
            if ($variables.viewMode.Value -eq [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::Select) {
                if ((Test-Path $fullPath) -eq $false) {
                    $variables.newRenderingView.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorViewFileDoesNotExist)) + " ($fullPath)"
                    continue
                }
            }
            
            if($variables.viewMode.Value -eq [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::Copy){
                if ((Test-Path $fullPath) -eq $true) {
                    $variables.newRenderingView.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorRenderingViewWithThisNameAlreadyExists))
                    continue
                }
                
                $lastSlashIndex = $fullPath.LastIndexOf("\")
                $lastDotIndex = $fullPath.LastIndexOf(".")
                $folderPath = $fullPath.Substring(0, $lastSlashIndex + 1)
                $fileName = $fullPath.Substring($lastSlashIndex + 1, $fullPath.Length - $lastSlashIndex - 1)
                
                if($lastSlashIndex -gt $lastDotIndex){
                    $variables.newRenderingView.Error =  ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::MissingFileNameErrorMessage))
                    continue
                }
                
                if((Test-Path -Path $folderPath) -ne $true){
                    $variables.newRenderingView.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FolderDoesNotExistErrorMessage))
                    continue
                }
                
                if(([System.IO.Path]::GetExtension($fileName) -ne ".cshtml")){
                    $variables.newRenderingView.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InvalidFileNameErrorMessage))
                    continue
                }
                
                if($fileName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ne -1){
                    $variables.newRenderingView.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InvalidFileNameErrorMessage))
                    continue
                }
            }

            if (($variables.targetModule.Value.Children | ? { $_.Name -eq $variables.newRenderingName.Value })) {
                $variables.newRenderingName.Error = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ErrorRenderingWithThisNameAlreadyExists))
                continue
            }
        } `
            -ValidatorParameters @{RenderingID = $CurrentRendering.ID}
        if ($result -ne "ok") {
            Exit
        }
        
        if (Test-IsHeadlessRendering($renderingType)) {
          $newRenderingView = ""
          $viewMode = [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::UseExisting
        }

        $model = New-Object "Sitecore.XA.Foundation.Scaffolding.Models.CopyRenderingModel"
        $model.SourceRenderingItem = $CurrentRendering
        $model.RenderingName = $newRenderingName
        $model.TargetModule = $targetModule
        $model.Class = $newRenderingClass
        $model.View = $newRenderingView
        $model.ViewMode = $viewMode
        $model.RenderingParametersMode = $renderingParametersMode
        $model.DatasourceMode = $datasourcesMode
        $model.RenderingType = $renderingType
        $model
    }

    end {
        Write-Verbose "Cmdlet Get-CloneRenderingDialog - End"
    }
}