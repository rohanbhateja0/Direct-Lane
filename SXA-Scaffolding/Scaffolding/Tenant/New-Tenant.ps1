Import-Function Add-BaseTemplate
Import-Function Add-FolderStructure
Import-Function Get-TenantItem
Import-Function Get-OrderedDictionaryByKey
Import-Function Get-Action
Import-Function Get-TenantDefinition
Import-Function Get-TenantThemesFolder
Import-Function Get-TenantMediaLibraryRoot
Import-Function Invoke-InputValidationStep
Import-Function Invoke-PostSetupStep
Import-Function Select-InheritingFrom

function Show-NewTenantDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantLocation
    )

    begin {
        Write-Verbose "Cmdlet Show-NewTenantDialog - Begin"
    }

    process {
        Write-Verbose "Cmdlet Show-NewTenantDialog - Process"

        $dialogOptions = New-Object System.Collections.Specialized.OrderedDictionary

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::GettingValidTenantDefinitions)) -PercentComplete 0
        [Item[]]$allDefinitions = Get-TenantDefinition "*"
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingDialogOptions)) -PercentComplete 60
        $nonSystemDefinitions = $allDefinitions | ? { $_ -ne $null } | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IsSystemModule']).Checked -eq $false }
        $nonSystemDefinitions | % {
            $contextItem = Get-Item -Path master: -ID $_.ID
            $key = "$($_.Fields['Name'].Value)"
            $translatedFeatureName = $contextItem.Fields['Name'].Value

            if ([string]::IsNullOrEmpty($translatedFeatureName)) {
                $translatedFeatureName = $key
            }
            if ($dialogOptions.Contains($translatedFeatureName)) {
                $index = 2
                do {
                    $translatedFeatureName = $translatedFeatureName + " [$index]"
                    $index++
                } while ($dialogOptions.Contains($translatedFeatureName))
            }

            $dialogOptions.Add($translatedFeatureName, $_.ID)
        }

        $dialogOptions = Get-OrderedDictionaryByKey $dialogOptions
        $preSelectedDefinitions = $nonSystemDefinitions | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IncludeByDefault']).Checked -eq $true } | % { $_.ID }

        $parameters = @()
        $parameters += @{ Name = "tenantName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::TenantName)}
        if ($dialogOptions.Count -gt 0) {
            $parameters += @{ Name = "preSelectedDefinitions"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Features); Options = $dialogOptions; Editor = "checklist"; Tip = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SelectTheFeaturesWhichShouldBeUsedInTenant); Height = "330px"}
        }

        $tenantName = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewTenant)
        do {
            Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::OpeningNewTenantDialog)) -PercentComplete 100
            $result = Read-Variable -Parameters $parameters `
                -Description $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThisScriptCreatesANewTenantWithinYourSxaEnabledInstance)) `
                -Title $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreateATenant)) -Width 500 -Height 600 `
                -OkButtonName $([Sitecore.Globalization.Translate]::Text("OK")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) `
                -Validator {
                $tenantName = $variables.tenantName.Value;
                $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
                if ($tenantName.Length -gt 100) {
                    $variables.tenantName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                    continue
                }
                if ([System.Text.RegularExpressions.Regex]::IsMatch($tenantName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                    $variables.tenantName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $tenantName
                    continue
                }
                if ($forbiddenTenantNames -contains $tenantName -eq $true) {
                    $variables.tenantName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::TenantWithThatNameAlreadyExists))
                    continue
                }
            } `
                -ValidatorParameters @{forbiddenTenantNames = ($TenantLocation.Children | Select-InheritingFrom ([Sitecore.XA.Foundation.Multisite.Templates+_BaseTenant]::ID.ToString()) | % { $_.Name} )}

            if ($result -ne "ok") {
                Close-Window
                Exit
            }

            $definitionItems = New-Object System.Collections.ArrayList($null)
            if ($preSelectedDefinitions ) {
                Write-Verbose "Adding pre-selected features"
                [Item[]]$preSelectedDefinitionItems = ($preSelectedDefinitions | % { Get-Item -Path master: -ID $_ })
                $definitionItems.AddRange($preSelectedDefinitionItems)
            }
            [Item[]]$systemFeatures = $allDefinitions | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IsSystemModule']).Checked -eq $true }
            if ($systemFeatures) {
                Write-Verbose "Adding system features"
                $definitionItems.AddRange($systemFeatures)
            }
        
            $model = New-Object Sitecore.XA.Foundation.Scaffolding.Models.CreateNewTenantModel
            $model.TenantName = $tenantName.TrimEnd(" ")
            $model.DefinitionItems = $definitionItems
            $model.TenantLocation = $TenantLocation
            $inputValidationResult = Invoke-PreTenantCreationValidation $model            
        } while (-not($inputValidationResult))

        
        $model
    }

    end {
        Write-Verbose "Cmdlet Show-NewTenantDialog - End"
    }
}

function New-Tenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Sitecore.XA.Foundation.Scaffolding.Models.CreateNewTenantModel]$Model
    )

    begin {
        Write-Verbose "Cmdlet New-Tenant - Begin"
    }

    process {
        Write-Verbose "Cmdlet New-Tenant - Process"
        New-UsingBlock (New-Object Sitecore.Data.BulkUpdateContext) {
            if ($Model.TenantName -and $Model.DefinitionItems) {
                Add-Tenant $Model.TenantLocation ($Model.TenantName) ($Model.DefinitionItems) $SitecoreContextItem.Language.Name                
                Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InvokingPostTenantSetupSteps)) -PercentComplete 100
                Invoke-PostTenantSetupStep $Model
                Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation "" -PercentComplete 100
            }
            else {
                Write-Error "Could not create tenant. Tenant name or module definitions is undefined"
            }
        }
    }
    end {
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::YourTenantHasBeenCreated)) -CurrentOperation "" -PercentComplete 100
        Write-Verbose "Cmdlet New-Tenant - End"
    }
}

function Invoke-PreTenantCreationValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Sitecore.XA.Foundation.Scaffolding.Models.CreateNewTenantModel]$Model
    )

    begin {
        Write-Verbose "Cmdlet Invoke-PreTenantCreationValidation - Begin"
    }

    process {
        Write-Verbose "Cmdlet Invoke-PreTenantCreationValidation - Process"
        Invoke-InputValidationStep $Model.DefinitionItems $Model
    }

    end {
        Write-Verbose "Cmdlet Invoke-PreTenantCreationValidation - End"
    }
}

function Add-Tenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantLocation,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TenantName,

        [Parameter(Mandatory = $true, Position = 2 )]
        [Item[]]$DefinitionItems,
        
        [Parameter(Mandatory = $false, Position = 3 )]
        [string]$Language = "en"	        
    )

    begin {
        Write-Verbose "Cmdlet Add-Tenant - Begin"
        Import-Function Set-TenantTemplate
        Import-Function Invoke-TenantAction
        Import-Function Add-TenantTemplateRoot
        Import-Function Add-TenantTemplate
        Import-Function Set-InsertOptionsForTenantTemplate
        Import-Function Add-TenantMediaLibrary
    }

    process {
        Write-Verbose "Cmdlet Add-Tenant - Process"

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SearchingItemsRoots)) -PercentComplete 0
        $_Project_Templates = Get-Item -Path master: -ID "{825B30B4-B40B-422E-9920-23A1B6BDA89C}"
        $_Project_Media = Get-Item -Path master: -ID "{90AE357F-6171-4EA9-808C-5600B678F726}"
        $_SXA_Themes_Root = Get-Item -Path master: -ID "{3CE9A090-FB9B-42BE-B593-F39BFCB1DE2B}"

        $tenantBranch = Get-Item -Path master: -ID "{9A4AAD67-383B-4504-93B9-D3502BE2B59D}"

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::GettingScafofldingActions)) -PercentComplete 5
        $actions = $DefinitionItems | Get-Action
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingTenantTemplatesRoot)) -PercentComplete 10
        $tenantTemplatesRoot = Add-TenantTemplateRoot $TenantLocation $TenantName $_Project_Templates
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddingTenantTemplates)) -PercentComplete 15
        $tenantTemplates = New-Object System.Collections.ArrayList($null)
        [Item[]]$tenantTemplatesFromDefinitionItems = Add-TenantTemplate $tenantTemplatesRoot $DefinitionItems
        [Item[]]$commonTenantTemplates = Add-CommonTenantTemplate $tenantTemplatesRoot $tenantTemplatesFromDefinitionItems
        $tenantTemplates.AddRange($tenantTemplatesFromDefinitionItems)
        if ($commonTenantTemplates.Count -gt 0) {
            $tenantTemplates.AddRange($commonTenantTemplates)
        }

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingTenantItem)) -PercentComplete 20
        $tenant = New-Item -Parent $TenantLocation -Name $TenantName -ItemType $tenantBranch.Paths.FullPath -Language $Language

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingTenantMediaLibrary)) -PercentComplete 25
        $tenantMediaLibrary = Add-TenantMediaLibrary $tenant $_Project_Media
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingSharedMediaLibrary)) -PercentComplete 31
        $sharedMediaLibrary = New-Item -Parent $tenantMediaLibrary -Name "shared" -ItemType "/System/Media/Media folder"
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingTenantThemesFolder)) -PercentComplete  32
        $tenantThemesFolder = Add-TenantThemesFolder $tenant $_SXA_Themes_Root

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::UpdatingTenantSettings)) -PercentComplete 33
        $tenant.Themes = $tenantThemesFolder.ID
        $tenant.Templates = $tenantTemplatesRoot.ID
        $tenant.MediaLibrary = $tenantMediaLibrary.ID
        $tenant.SharedMediaLibrary = $sharedMediaLibrary.ID

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::UpdatingInsertOptionsForTenantTemplates)) -PercentComplete 35
        Set-InsertOptionsForTenantTemplate $tenantTemplates
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::EditingTenantTemplates)) -PercentComplete 40
        # $actions | ? { $_.TemplateName -eq "EditTenantTemplate" }    | % { Invoke-TenantAction   $tenant $_ }
        $percentage_start = 40
        $percentage_end = 70
        $percentage_diff = $percentage_end - $percentage_start        
        $editTemplateActions = $actions | ? { $_.TemplateName -eq "EditTenantTemplate" }
        foreach ($actionItem in $editTemplateActions) {
            $currentIndex = $editTemplateActions.IndexOf($actionItem)
            $percentComplete = ($percentage_start + 1.0 * $percentage_diff * ($currentIndex) / ($editTemplateActions.Count))
            $currentOperation = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::EditingTemplate)) -f $actionItem.Name
            Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ($currentOperation) -PercentComplete $percentComplete
            Invoke-TenantAction  $tenant $actionItem
        }

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ApplyingTenantTemplatesToItems)) -PercentComplete 70
        Set-TenantTemplate $tenant $tenantTemplates
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddingItemsFromScaffoldingActions)) -PercentComplete 80
        $actions | ? { $_.TemplateName -eq "AddItem" }               | % { Invoke-TenantAction   $tenant $_  $tenant.Language.Name}
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InvokingScriptsFromScaffoldingActions)) -PercentComplete 90
        $actions | ? { $_.TemplateName -eq "ExecuteScript" }         | % { Invoke-TenantAction   $tenant $_ }
        $tenant = $tenant.Database.GetItem($tenant.ID) | Wrap-Item
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text("Finishing")) -PercentComplete 100
        $tenant.Modules = $DefinitionItems.ID -join "|"
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewTenant)) -CurrentOperation "" -PercentComplete 100
    }

    end {
        Write-Verbose "Cmdlet Add-Tenant - End"
    }
}

function Invoke-PostTenantSetupStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Sitecore.XA.Foundation.Scaffolding.Models.CreateNewTenantModel]$Model
    )

    begin {
        Write-Verbose "Cmdlet Invoke-PostTenantSetupStep - Begin"
    }

    process {
        Write-Verbose "Cmdlet Invoke-PostTenantSetupStep - Process"
        Invoke-PostSetupStep $Model.DefinitionItems $Model
    }

    end {
        Write-Verbose "Cmdlet Invoke-PostTenantSetupStep - End"
    }
}

function Add-TenantThemesFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Tenant,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$FoundationThemesRoot
    )

    begin {
        Write-Verbose "Cmdlet Add-TenantMediaLibrary - Begin"
    }

    process {
        $tenantTail = $Tenant.Paths.Path.Substring(("/sitecore/content").Length)
        $path = $FoundationThemesRoot.Paths.Path + $tenantTail
        Add-FolderStructure $path
    }

    end {
        Write-Verbose "Cmdlet Add-TenantMediaLibrary - End"
    }
}

function Add-CommonTenantTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantTemplateLocation,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$TenantTemplates
    )

    begin {
        Write-Verbose "Cmdlet Add-CommonTenantTemplate - Begin"
        Import-Function New-TenantTemplate
        Import-Function Get-ProjectTemplateBasedOnBaseTemplate
    }

    process {
        [Sitecore.Data.ID[]]$staticSourceTemplates = @(
            [Sitecore.XA.Foundation.Multisite.Templates+Home]::ID
            [Sitecore.XA.Foundation.Multisite.Templates+Page]::ID
            [Sitecore.XA.Foundation.Multisite.Templates+Settings]::ID
        )
        $staticSourceTemplates | % {
            $template = $_
            $existing = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $template
            if ($existing -eq $null) {
                New-TenantTemplate $TenantTemplateLocation $template
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Add-CommonTenantTemplate - End"
    }
}