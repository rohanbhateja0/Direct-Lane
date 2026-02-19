Import-Function Add-FolderStructure
Import-Function Get-ItemByIdSafe

function Copy-RenderingItem ($model) {
    Write-Verbose "Copying rendering item"
    if (($destinationModule.Children | ? { $_.Name -eq $model.RenderingName }) -eq $null) {
        $newRenderingItem = $model.SourceRenderingItem.CopyTo($model.TargetModule, $model.RenderingName) | Wrap-Item
        $newRenderingItem."__Display Name" = ""
        if ($newRenderingItem."componentName" -ne $null) {
          $newRenderingItem."componentName" = $model.RenderingName
        }
        $newRenderingItem
    }
    else {
        Write-Host "Rendering already exists, do nothing. exiting"
        return
    }
}

function Copy-RenderingRenderingParameters ($model) {
    Write-Verbose "Copying rendering parameters"
    $RenderingRenderingParameterTemplateItem = Get-RenderingRenderingParameterTemplateItem $model.SourceRenderingItem
    if ($RenderingRenderingParameterTemplateItem) {
        $TemplatesFolderForFeature = Get-TemplatesFolderForFeature $model.TargetModule
        if ($TemplatesFolderForFeature -eq $null) {
            Write-Host "Incomplete module (missing templates folder)"
            return
        }
        $renderingParametersItemName = $model.RenderingName
        $TemplatesFolderForFeature = Add-FolderStructure "$($TemplatesFolderForFeature.Paths.Path)/Rendering Parameters" "System/Templates/Template Folder"
        if ($model.RenderingParametersMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.RenderingParametersMode]::Inherit) {
            $newRenderingRenderingParameterTemplateItem = New-Item -ItemType "System/Templates/Template" -Parent $TemplatesFolderForFeature -Name $renderingParametersItemName | Wrap-Item
            $newRenderingRenderingParameterTemplateItem."__Base template" = $RenderingRenderingParameterTemplateItem.ID
        }
        if ($model.RenderingParametersMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.RenderingParametersMode]::Copy) {
            $templateItemName = Get-UniqueName $TemplatesFolderForFeature $renderingParametersItemName
            $newRenderingRenderingParameterTemplateItem = $RenderingRenderingParameterTemplateItem.CopyTo($TemplatesFolderForFeature, $renderingParametersItemName) | Wrap-Item
            $newRenderingRenderingParameterTemplateItem."__Display Name" = ""
        }
        $newRenderingRenderingParameterTemplateItem
    }
}

function Copy-TemplateItem ($model, $RenderingDatasourceTemplateItem, $Inherit) {
    if ($RenderingDatasourceTemplateItem) {
        $TemplatesFolderForFeature = Get-TemplatesFolderForFeature $model.TargetModule
        $templateItemName = $RenderingDatasourceTemplateItem.Name.Replace($model.SourceRenderingItem.Name, $model.RenderingName)
        if ($model.DatasourceMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.DatasourceMode]::Inherit) {
            $newRenderingDatasourceTemplateItem = New-Item -ItemType "System/Templates/Template" -Parent $TemplatesFolderForFeature -Name $templateItemName | Wrap-Item
            ($newRenderingDatasourceTemplateItem -as [Sitecore.Data.Items.TemplateItem]).CreateStandardValues() > $null
            $newRenderingDatasourceTemplateItem."__Base template" = $RenderingDatasourceTemplateItem.ID
            $newRenderingDatasourceTemplateItem."__Icon" = $RenderingDatasourceTemplateItem."__Icon"
        }
        if ($model.DatasourceMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.DatasourceMode]::Copy) {
            $templateItemName = Get-UniqueName $TemplatesFolderForFeature $templateItemName
            $newRenderingDatasourceTemplateItem = $RenderingDatasourceTemplateItem.CopyTo($TemplatesFolderForFeature, $templateItemName) | Wrap-Item
            $newRenderingDatasourceTemplateItem."__Display Name" = ""
        }
        $newRenderingDatasourceTemplateItem
    }
}

function Get-UniqueName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$ParentItem,
        [Parameter(Mandatory = $true, Position = 1 )]
        [string]$Name
    )
    $names = $ParentItem.Children.Name
    if($names){
        $tempName = $Name
        if ($names.Contains($Name)) {
            $index = 2
            do {
                $tempName = $Name + "_$index"
                $index++
            } while ($names.Contains($tempName))
        }
        $tempName        
    }else{
        $Name
    }
}

function Copy-DatasourceFolderItem ($model, $newRenderingDatasourceTemplateItem) {
    Write-Verbose "Copying datasource folder"
    $RenderingDatasourceTemplateItem = Get-RenderingDatasourceTemplateItem $model.SourceRenderingItem
    if ($RenderingDatasourceTemplateItem) {
        $RenderingDatasourceFolderTemplateItem = Get-RenderingDatasourceFolderTemplateItem $RenderingDatasourceTemplateItem
        if ($RenderingDatasourceFolderTemplateItem) {
            $TemplatesFolderForFeature = Get-TemplatesFolderForFeature $model.TargetModule

            if ($model.RenderingParametersMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.DatasourceMode]::Inherit) {
                $newRenderingDatasourceFolderTemplateItem = New-Item -ItemType "System/Templates/Template" -Parent $TemplatesFolderForFeature -Name "$($model.RenderingName) Folder" | Wrap-Item
                ($newRenderingDatasourceFolderTemplateItem -as [Sitecore.Data.Items.TemplateItem]).CreateStandardValues() > $null
                $newRenderingDatasourceFolderTemplateItem."__Base template" = $RenderingDatasourceFolderTemplateItem.ID
                $newRenderingDatasourceFolderTemplateItem."__Icon" = $RenderingDatasourceFolderTemplateItem."__Icon"

            }
            if ($model.RenderingParametersMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.DatasourceMode]::Copy) {
                $newRenderingDatasourceFolderTemplateItem = $RenderingDatasourceFolderTemplateItem.CopyTo($TemplatesFolderForFeature, "$($model.RenderingName) Folder") | Wrap-Item
                $newRenderingDatasourceFolderTemplateItem."__Display Name" = ""
            }

            Update-InsertOptions $newRenderingDatasourceFolderTemplateItem $RenderingDatasourceTemplateItem.ID          $newRenderingDatasourceTemplateItem.ID
            Update-InsertOptions $newRenderingDatasourceFolderTemplateItem $RenderingDatasourceFolderTemplateItem.ID    $newRenderingDatasourceFolderTemplateItem.ID
            $newRenderingItem."Datasource Location" = $newRenderingItem."Datasource Location".Replace($RenderingDatasourceFolderTemplateItem.Name, $newRenderingDatasourceFolderTemplateItem.Name)
            $newRenderingDatasourceFolderTemplateItem
        }
    }
}

function Add-AddDataFolderActionToSiteSetup ($siteSetupItem, $newRenderingDatasourceFolderTemplateItem, $renderingName) {
    Write-Verbose "Adding data folder to site setup actions"
    if ($newRenderingDatasourceFolderTemplateItem) {
      $addItemActionTemplate = "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem"
      $dataItemInBranchId = "{15497C63-5946-49F4-B0A2-FE50A600CFAC}"
      if ($siteSetupItem.Template.Name -eq "HeadlessSiteSetupRoot") {
        $addItemActionTemplate = "Foundation/JSS Experience Accelerator/Scaffolding/Actions/Site/AddItem"
        $dataItemInBranchId = "{BA2F959D-A614-4C92-8B57-F1FC1A323ABE}"
      }
      $addDataItem = New-Item -ItemType $addItemActionTemplate -Path $siteSetupItem.Paths.Path -Name "Add $($renderingName)s Data Item" | Wrap-Item
      $addDataItem.Location = $dataItemInBranchId
      $addDataItem.__Name = $renderingName
      $addDataItem.__Template = $newRenderingDatasourceFolderTemplateItem.ID
      $addDataItem
    }
}

function Test-ValidBranchTemplate ($EmptyAvailableRenderings, $availableRenderingsAction) {
    $branch = $EmptyAvailableRenderings.Database.GetItem($availableRenderingsAction.Fields['Template'].Value)
    $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
    $availableRenderingsItem.Template.ID -eq $EmptyAvailableRenderings.ID
}

function Add-AddToAvailableRenderingsItem ($model, $siteSetupItem, $newRenderingItem) {
    $renderingId = $model.SourceRenderingItem.ID
    $availableRenedringsItemFromBranch = $newRenderingItem.Database.DataManager.DataSource.SelectIDs("`$name", $null, "{715AE6C0-71C8-4744-AB4F-65362D20AD65}", "*$renderingId*", $true) | % { Get-ItemByIdSafe $_ } | Select-Object -First 1
    $availableRenedringsItemId = "{84179507-91A2-47EA-A424-9D338F64C953}"
    $addItemActionTemplate = "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem"
    $emptyAvailableRenderingsBranchPath = "/sitecore/templates/Branches/Foundation/Experience Accelerator/Scaffolding/Empty Available Renderings"
    $availableRenderingsPrefix = ""
    
    if (Test-IsHeadlessRendering($model.RenderingType)) {
      $availableRenedringsItemId = "{3F14C1B6-5A2D-44CA-A8EF-DFE3CBD574E4}"
      $addItemActionTemplate = "Foundation/JSS Experience Accelerator/Scaffolding/Actions/Site/AddItem"
      $availableRenderingsPrefix = "Headless "
    }

    if ($availableRenedringsItemFromBranch) {
        $availableRenderingsAction = Get-ChildItem -Path $siteSetupItem.Paths.Path -Recurse | ? { $_.TemplateName -eq "AddItem" } | ? { $_.Location -eq $availableRenedringsItemId } | Select-Object -First 1
        if ($availableRenderingsAction -and (Test-ValidBranchTemplate $availableRenedringsItemFromBranch.Template $availableRenderingsAction)) {
            $branch = $model.TargetModule.Database.GetItem($availableRenderingsAction.Fields['Template'].Value)
            $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
        }
        else {
            $availableRenderingsAction = New-Item -ItemType $addItemActionTemplate -Path $siteSetupItem.Paths.Path -Name "Add Available Renderings" | Wrap-Item
            $availableRenderingsAction."Location" = $availableRenedringsItemId
            $availableRenderingsAction.__Name = $model.TargetModule.Name
            $TemplatesFolderForFeature = Get-BranchesFolderForFeature $model.TargetModule
            if ($TemplatesFolderForFeature -eq $null) {
                $TemplatesFolderForFeature = Get-TemplatesFolderForFeature $model.TargetModule
            }
            $emptyAvailableRenderingsBranch = Get-Item -Path $emptyAvailableRenderingsBranchPath
            $branch = $emptyAvailableRenderingsBranch.CopyTo($TemplatesFolderForFeature, "Available $availableRenderingsPrefix$($model.TargetModule.Name) Renderings") | Wrap-Item
            $branch."__Display Name" = ""
            $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
            $availableRenderingsItem.ChangeTemplate($availableRenedringsItemFromBranch.Template)
            $availableRenderingsAction."__Template" = $branch.ID
        }
        $availableRenderingsItem.Renderings = ($availableRenderingsItem.Renderings, $newRenderingItem.ID) -join "|"
        $availableRenderingsItem
    }
}

function Set-RenderingView($model, $newRenderingItem) {
    $newRenderingItem.Fields.ReadAll()
    if($newRenderingItem.Fields.Name.Contains("RenderingViewPath")){
        $renderingViewPath = Get-RenderingViewPath $model.SourceRenderingItem
        $renderingViewPath = if ($renderingViewPath -eq $null) {""} else {$renderingViewPath}
        if ($model.ViewMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::UseExisting) {
            $newRenderingItem."RenderingViewPath" = $renderingViewPath
        }
        if ($model.ViewMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::Copy) {
            $sourceRenderingViewPath = $renderingViewPath
            $sourceRenderingFullViewPath = Join-Path $AppPath $sourceRenderingViewPath.TrimStart("~")
            $destinationPath = Join-Path $AppPath $model.View.TrimStart("~")
            $viewFile = Get-Item $sourceRenderingFullViewPath
            try {
                $viewFile.CopyTo($destinationPath) > $null
                $newRenderingItem."RenderingViewPath" = $r.View
            } catch [System.UnauthorizedAccessException] {
                $errorMessage = "Couldn't copy rendering. Access to the path '$destinationPath' is denied."
                Write-Verbose $errorMessage
                [Sitecore.Diagnostics.Log]::Error($errorMessage, "")
            }            
        }
        if ($model.ViewMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.ViewMode]::Select) {
            $newRenderingItem."RenderingViewPath" = $r.View
        }
    }
}

function Get-InsertOptionAsItem($DatasourceItem) {
    $db = $DatasourceItem.Database
    $svFIeldValue = $DatasourceItem."__Standard values"
    if ($svFIeldValue -ne "" -and $svFIeldValue -ne $null) {
        $svItem = $db.GetItem($DatasourceItem."__Standard values") | Wrap-Item
        $svItem.__Masters.Split("|") | ? { [guid]::TryParse($_, [ref][guid]::Empty) } | % {
            $db.GetItem($_) | Wrap-Item
        }
    }
}

function Add-DatasourceTemplateRecursive($model, $DatasourceItem, $processed) {
    if ($processed -eq $null) {
        $processed = @()
    }
    Get-InsertOptionAsItem $DatasourceItem | % {
        if ($processed.IndexOf($_.ID) -eq -1) {
            $templateToCopy = $_
            $processed += $templateToCopy.ID
            $newTemplate = Copy-TemplateItem $model $templateToCopy
            @{oldTemplateID = $templateToCopy.ID ; newTemplateID = $newTemplate.ID}
            $svFIeldValue = $DatasourceItem."__Standard values"
            if ($svFIeldValue -ne "" -and $svFIeldValue -ne $null) {
                $db = $DatasourceItem.Database
                $svItem = $db.GetItem($svFIeldValue) | Wrap-Item
                $svItem."__Masters" = $svItem."__Masters".Replace($templateToCopy.ID, $newTemplate.ID)
                Add-DatasourceTemplateRecursive $templateToCopy
            }
        }
    }
}

function Set-BranchTemplate ($RenderingDatasourceBranchItem, $mappingTable) {
    Get-ChildItem -Path $RenderingDatasourceBranchItem.Paths.Path -Recurse | % {
        $branchItem = $_
        if ($mappingTable.Contains($branchItem.Template.ID)) {
            $newTemplateID = $mappingTable[$branchItem.Template.ID]
            $newTemplateItem = $model.SourceRenderingItem.Database.GetItem($newTemplateID)
            $branchItem.ChangeTemplate($newTemplateItem)
        }
    }
}

function Get-TemplateIfBranch ($RenderingDatasourceTemplateItem) {
    if ($RenderingDatasourceTemplateItem.TemplateName -eq "Branch") {
        $branchItem = $RenderingDatasourceTemplateItem.Children | Select-Object -First 1
        $RenderingDatasourceTemplateItem = $branchItem.Template.InnerItem | Wrap-Item
    }
    $RenderingDatasourceTemplateItem
}

function Get-RenderingSiteSetupAddItem(){
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Model", Position = 0)]
        [Sitecore.XA.Foundation.Scaffolding.Models.CopyRenderingModel]$model,
        [Parameter(Mandatory = $true, ParameterSetName = "Name", Position = 0)]
        [string]$sourceRenderingName
    )
    
    begin {
      Write-Verbose "Cmdlet Get-RenderingSiteSetupAddItem - Begin"
    }

    process {
      Write-Verbose "Cmdlet Get-RenderingSiteSetupAddItem - Process"
      $siteSetupRenderingVariantsTemplateID = "{5CDC5EB2-F14F-4495-88E8-AA882DDFAA05}"
      $addItemActionTemplateID = "{EA8A3F26-9CCD-443A-95F5-71B868A94BD0}"
      $addItemActionLocationFieldID = "{4795A7C6-08A9-4248-86C3-D460062C3A22}"
      $renderingName = switch ($PSCmdlet.ParameterSetName)
      {
          "Model" { $model.SourceRenderingItem.Name; Break }
          "Name" { $sourceRenderingName; Break }
      }
      
      if ($PSCmdlet.ParameterSetName -eq "Model" -and (Test-IsHeadlessRendering($model.RenderingType))) {
        $siteSetupRenderingVariantsTemplateID = "{C6F65339-F4DA-40FA-88D1-E1ECFFD54B91}"
        $addItemActionTemplateID = "{3AEA335C-D06D-45B1-841A-CBC8D2D1CE40}"
        $addItemActionLocationFieldID = "{52C91C75-6698-4701-A8A2-242ACE59A8D6}"
      }
      
      $db = Get-Database "master"
      $db.DataManager.DataSource.SelectIDs($null, $addItemActionTemplateID, $addItemActionLocationFieldID, $siteSetupRenderingVariantsTemplateID, $false) `
          | % { Get-ItemByIdSafe $_ } `
          | ? { $_._Name -eq $renderingName }
      }

    end {
      Write-Verbose "Cmdlet Get-RenderingSiteSetupAddItem - End"
    }
}

function Copy-RenderingSiteSetupAddRenderingVariantsItemAction($model, $defaultRenderingVariantBranch, $newRenderingSiteSetupRootItem){
    #Get system rendering path
    $destinationRenderingName = $model.RenderingName
    $siteLevelRenderingVariant = Get-RenderingSiteSetupAddItem $model
    
    #Check if rendering has site level rendering Variants
    if($siteLevelRenderingVariant -ne $null){
        #1. Get destination folder for new AddItem Action Item
        $newRenderingSiteSetupAddRVFolderName = "Rendering Variants"
        $siteSetupTemplateID = "{292CCFCD-7790-4692-856B-76014B8038E7}"
        $folderTemplateID = "{A87A00B1-E6DB-45AB-8B54-636FEC3B5523}"
        
        if (Test-IsHeadlessRendering($model.RenderingType)) {
          $newRenderingSiteSetupAddRVFolderName = "Headless Variants"
          $siteSetupTemplateID = "{BED31D6F-D968-45A9-B54E-12D7F977D861}"
        }
        
        if(![Sitecore.Data.Managers.TemplateManager]::GetTemplate($siteLevelRenderingVariant.Parent).InheritsFrom($siteSetupTemplateID) -and [Sitecore.Data.Managers.TemplateManager]::GetTemplate($siteLevelRenderingVariant.Parent).InheritsFrom($folderTemplateID)){
            $newRenderingSiteSetupAddRVFolderName = $siteLevelRenderingVariant.Parent.Name
        }
        $newRenderingSiteSetupAddRVFolderPath = $newRenderingSiteSetupRootItem.Paths.Path + "/" + $newRenderingSiteSetupAddRVFolderName
        if(Test-Path $newRenderingSiteSetupAddRVFolderPath){
            $newRenderingSiteSetupAddRVFolder = Get-Item -Path $newRenderingSiteSetupAddRVFolderPath
        }
        
        # If it does not exist, create new one
        if($newRenderingSiteSetupAddRVFolder -eq $null) {
            $newRenderingSiteSetupAddRVFolder = New-Item -ItemType "/sitecore/templates/Common/Folder" -Parent $newRenderingSiteSetupRootItem -Name $newRenderingSiteSetupAddRVFolderName
        }
        
        #2. Copy Source Rendering AddItem Action Item
        $destinationParentItem = $newRenderingSiteSetupAddRVFolder | Wrap-Item
        $copiedItem = $siteLevelRenderingVariant.CopyTo($destinationParentItem, $destinationRenderingName) | Wrap-Item
        
        #3. Change newly created AddItem Action Item fields (not standard one)
        $copiedItem._Name = $destinationRenderingName
        $copiedItem._Template = $defaultRenderingVariantBranch.ID.ToString()
    }
}

function Copy-RenderingSystemRenderingVariants($model, $newRenderingDefaultBranch){
    $sourceRenderingName = $model.SourceRenderingItem.Name
    
    #Check if system rendering exists
    $renderingVariantsRepository = Get-RenderingVariantsRepository
    $renderingVariantsRepository.GetSystemVariants($sourceRenderingName) | ForEach-Object{
        if($_ -ne $null){
            $newDefaultRenderingVariantParent = $newRenderingDefaultBranch.Children | Select-Object -First 1
            $_.CopyTo($newDefaultRenderingVariantParent, $_.Name) > $null
        }    
    }
    
}

function Create-DefaultVariantBranchForNewRendering($model, $newFeatureBranchFolder){
    $branchTemplateID = "{35E75C72-4985-4E09-88C3-0EAC6CD1E64F}"
    $variantsTemplatePath = "Foundation/Experience Accelerator/Rendering Variants/Variants"
    
    if (Test-IsHeadlessRendering($model.RenderingType)) {
      $variantsTemplatePath = "Foundation/JSS Experience Accelerator/Headless Variants/HeadlessVariants"
    }
    
    $newDefaultVariantName = 'Default ' + $model.RenderingName + ' Variant'
    
    $siteLevelRenderingVariant = Get-RenderingSiteSetupAddItem $model
    if($siteLevelRenderingVariant -ne $null){
        $siteSetupAddItemTemplateFieldValue = $siteLevelRenderingVariant._Template
        
        $siteSetupAddItemTemplateItem = $model.SourceRenderingItem.Database.GetItem($siteSetupAddItemTemplateFieldValue)
        if([Sitecore.Data.Managers.TemplateManager]::GetTemplate($siteSetupAddItemTemplateItem).InheritsFrom($branchTemplateID)){
            $newDefaultVariantBranch = $siteSetupAddItemTemplateItem.CopyTo($newFeatureBranchFolder, $newDefaultVariantName) | Wrap-Item
        }
        else{
            $newDefaultVariantBranch = New-Item -ItemType "System/Branches/Branch" -Parent $newFeatureBranchFolder -Name $newDefaultVariantName | Wrap-Item
            New-Item -ItemType $variantsTemplatePath -Parent $newDefaultVariantBranch -Name '$name' > $null
        }
    }
    $newDefaultVariantBranch
}

function Get-RenderingVariantsRepository {
  [CmdletBinding()]
  param()

  begin {
    Write-Verbose "Cmdlet Get-RenderingVariantsRepository - Begin"
  }

  process {
    Write-Verbose "Cmdlet Get-RenderingVariantsRepository - Process"
    $serviceProvider = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
    $service = $serviceProvider.GetType().GetMethod('GetService').Invoke($serviceProvider, [Sitecore.XA.Foundation.Variants.Abstractions.Services.IRenderingVariantsRepository])
    return $service
  }

  end {
    Write-Verbose "Cmdlet Get-RenderingVariantsRepository - End"
  }
}

function Copy-Rendering {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Sitecore.XA.Foundation.Scaffolding.Models.CopyRenderingModel]$r
    )

    begin {
        Write-Verbose "Cmdlet Copy-Rendering - Begin"
        Import-Function Get-CloneRenderingDialog
        Import-Function Get-TemplatesFolderForFeature
        Import-Function Get-RenderingRenderingParameterTemplateItem
        Import-Function Get-RenderingDatasourceTemplateItem
        Import-Function Get-RenderingDatasourceFolderTemplateItem
        Import-Function Get-RenderingSimpleDatasourceTemplateItem
        Import-Function Get-SettingsFolderForFeature
        Import-Function Get-SiteDefinitions
        Import-Function Update-InsertOptions
        Import-Function Get-SiteSetupForModule
        Import-Function Get-BranchesFolderForFeature
        Import-Function Add-SetupItemDependency
        Import-Function Get-RenderingViewPath
        Import-Function Test-IsHeadlessRendering
    }

    process {
        Write-Verbose "Cmdlet Copy-Rendering - Process"
        $renderingName = $r.RenderingName
        Write-Verbose "Processing $renderingName"

        ### copy rendering item
        $newRenderingItem = Copy-RenderingItem $r
        $newRenderingItem."RenderingCssClass" = $r.Class
        Set-RenderingView $r $newRenderingItem
        ### copy rendering parameters
        if ($r.SourceRenderingItem."Parameters Template") {
            $newRenderingRenderingParameterTemplateItem = Copy-RenderingRenderingParameters $r
            $newRenderingItem."Parameters Template" = $newRenderingRenderingParameterTemplateItem.ID
        }

        if ($r.SourceRenderingItem."Datasource Template") {
            $templateMapping = New-Object -TypeName "System.Collections.Hashtable"
            ### copy datasource
            $RenderingDatasourceTemplateItem = Get-RenderingDatasourceTemplateItem $r.SourceRenderingItem
            if ($RenderingDatasourceTemplateItem.TemplateName -eq "Branch") {
                $RenderingDatasourceBranchItem = $RenderingDatasourceTemplateItem
                $branchItem = $RenderingDatasourceTemplateItem.Children | Select-Object -First 1
                $RenderingDatasourceTemplateItem = $branchItem.Template.InnerItem | Wrap-Item
            }

            $newRenderingDatasourceTemplateItem = Copy-TemplateItem $r $RenderingDatasourceTemplateItem
            ### copy ds recursively
            $mappingTable = Add-DatasourceTemplateRecursive $r $newRenderingDatasourceTemplateItem
            if ($RenderingDatasourceBranchItem) {
                $model = New-Object -TypeName "Sitecore.XA.Foundation.Scaffolding.Models.CopyRenderingModel" -ArgumentList $r
                $model.DatasourceMode = [Sitecore.XA.Foundation.Scaffolding.Models.DatasourceMode]::Copy
                $model.RenderingName += " Branch"
                $newRenderingDatasourceBranchItem = Copy-TemplateItem $model $RenderingDatasourceBranchItem
                $templateMapping.Add($RenderingDatasourceTemplateItem.ID, $newRenderingDatasourceTemplateItem.ID)
                $mappingTable | % {$templateMapping.Add($_.oldTemplateID, $_.newTemplateID)}
                Set-BranchTemplate $newRenderingDatasourceBranchItem $templateMapping
                $newRenderingItem."Datasource Template" = $newRenderingDatasourceBranchItem.Paths.Path

            }
            else {
                $newRenderingItem."Datasource Template" = $newRenderingDatasourceTemplateItem.Paths.Path
            }

            ### copy datasource folder
            if ($newRenderingDatasourceBranchItem) {
                $newRenderingDatasourceFolderTemplateItem = Copy-DatasourceFolderItem $r $newRenderingDatasourceBranchItem
            }else {
                $newRenderingDatasourceFolderTemplateItem = Copy-DatasourceFolderItem $r $newRenderingDatasourceTemplateItem
            }
        }

        # get site setup item
        $settingsFolderForFeature = Get-SettingsFolderForFeature $r.TargetModule
        $siteSetupItem = Get-SiteSetupForModule $settingsFolderForFeature $r.RenderingType
        
        $addAvailableRenderingActionId = "{BDF83718-907A-435B-B1BA-64139E07983F}"
        if (Test-IsHeadlessRendering($r.RenderingType)) {
          $addAvailableRenderingActionId = "{24EC97FA-F22A-404E-BC39-9B0673D46271}"
        }
        Add-SetupItemDependency $siteSetupItem $addAvailableRenderingActionId

        Add-AddToAvailableRenderingsItem $r $siteSetupItem $newRenderingItem > $null

        if ($newRenderingDatasourceFolderTemplateItem) {
            Add-AddDataFolderActionToSiteSetup $siteSetupItem $newRenderingDatasourceFolderTemplateItem $renderingName > $null
        }
        
        ### copy rendering variants
        $newFeatureBranchFolder = Get-BranchesFolderForFeature $r.TargetModule
        
        # create Default Branch for new rendering
        $newRenderingDefaultBranch = Create-DefaultVariantBranchForNewRendering $r $newFeatureBranchFolder
    
        # check default branch exists for the feature
        if($newRenderingDefaultBranch -ne $null){
            Copy-RenderingSystemRenderingVariants $r $newRenderingDefaultBranch
            Copy-RenderingSiteSetupAddRenderingVariantsItemAction $r $newRenderingDefaultBranch $siteSetupItem
        }
        
        $destinationItemID = $newRenderingItem.ID.ToString()
        $host.PrivateData.CloseMessages.Add("item:load(id=$destinationItemID)")
    }

    end {
        Write-Verbose "Cmdlet Copy-Rendering - End"
    }
}