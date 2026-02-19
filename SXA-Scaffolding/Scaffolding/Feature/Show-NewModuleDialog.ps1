function Show-NewModuleDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentItem
    )

    begin {
        Write-Verbose "Cmdlet Show-NewModuleDialog - Begin"
        Import-Function Get-ModuleStartLocation
        Import-Function Get-Layer
    }

    process {
        Write-Verbose "Cmdlet Show-NewModuleDialog - Process"

        $availableContainers = Get-ModuleStartLocation
        $selectedContainers = $availableContainers.Values
        
        $availableSetupTemplates = New-Object System.Collections.Specialized.OrderedDictionary
        $availableSetupTemplates.Add("Tenant Setup", "{141DF88E-7156-4D2E-A004-C8C1A7C51E9D}")
        $availableSetupTemplates.Add("Site Setup", "{292CCFCD-7790-4692-856B-76014B8038E7}")
        
        $selectedSetupTemplates = $availableSetupTemplates.Values

        $dialogParmeters = @()
        $dialogParmeters += @{ Name = "newFeatureName"; Value = ""; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FeatureName)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General))}
        $dialogParmeters += @{ Name = "targetModule"; Value = $CurrentItem; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FeatureLocation)); Root = $Root.Paths.Path; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General))}
        $dialogParmeters += @{ Name = "selectedContainers"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FeatureContainers); Options = $availableContainers; Editor = "checklist"; Height = "200px"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General); }
        $dialogParmeters += @{ Name = "selectedSetupTemplates"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FeatureScaffoldingActions); Options = $availableSetupTemplates; Editor = "checklist"; Height = "30px"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General); }

        $result = Read-Variable -Parameters $dialogParmeters `
            -Description ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewFeatureDialogDescription)) `
            -Title ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewFeatureDialogTitle)) -Width 650 -Height 700 -OkButtonName "Proceed" -CancelButtonName "Abort" -ShowHints `
            -Validator {
                Import-Function Get-Layer
                $newFeatureName = $variables.newFeatureName.Value;
                $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
                if ($newFeatureName.Length -gt 100) {
                    $variables.newFeatureName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                    continue
                }
                if ([System.Text.RegularExpressions.Regex]::IsMatch($newFeatureName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                    $variables.newFeatureName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $newFeatureName
                    continue
                }
                $Layer = Get-Layer $variables.targetModule.Value
                $existingPaths = $availableContainers.Values | ? { 
                    $path = $_ -f "$($Layer)/"
                    $path += $variables.newFeatureName.Value
                    $item = $variables.targetModule.Value.Database.GetItem($path) | Wrap-Item
                    $item -ne $null
                }
                
                if ($existingPaths.Length -gt 0) {
                    $variables.newFeatureName.Error = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FeatureAlreadyExists);
                    continue
                }
        } -ValidatorParameters @{ 
            availableContainers = $availableContainers
        }


        if ($result -ne "ok") {
            Exit
        }
        
        if($selectedSetupTemplates.Count -gt 0 -and !$selectedContainers.Contains("/sitecore/system/Settings/{0}")){
            $selectedContainers+="/sitecore/system/Settings/{0}"
        }
        
        $Layer = Get-Layer $targetModule
        $layerRootPath = "/sitecore/system/Settings/{0}" -f $Layer
        
        $model = New-Object "Sitecore.XA.Foundation.Scaffolding.Models.NewModuleModel"
        $model.Tail                  = [regex]::Replace($targetModule.Paths.Path , $layerRootPath, "")
        $model.Roots                 = $selectedContainers | % { $_ -f $Layer} | % { Get-Item -Path $_ }
        $model.Name                  = $newFeatureName
        $model.SetupItemTemplatesIds = $selectedSetupTemplates
        $model
    }

    end {
        Write-Verbose "Cmdlet Show-NewModuleDialog - End"
    }
}