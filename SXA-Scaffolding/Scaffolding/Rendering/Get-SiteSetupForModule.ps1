function Get-SiteSetupForModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$ModuleSettingsRoot,
        [Parameter(Mandatory = $false, Position = 1 )]
        [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]$RenderingType
    )

    begin {
        Write-Verbose "Cmdlet Get-SiteSetupForModule - Begin"
        Import-Function Test-IsHeadlessRendering
    }

    process {
        Write-Verbose "Cmdlet Get-SiteSetupForModule - Process"
        $templateName = "SiteSetupRoot"
        $siteSetupRootPath = "Foundation/Experience Accelerator/Scaffolding/Roots/SiteSetupRoot"
        $siteSetupRootNamePrefix = ""
        
        if ($RenderingType -ne $null -and (Test-IsHeadlessRendering($RenderingType))) {
          $templateName = "HeadlessSiteSetupRoot"
          $siteSetupRootPath = "Foundation/JSS Experience Accelerator/Scaffolding/Roots/HeadlessSiteSetupRoot"
          $siteSetupRootNamePrefix = "Headless "
        }
        $SiteSetupRoot = Get-ChildItem -Path $ModuleSettingsRoot.Paths.Path -Recurse | ? { $_.TemplateName -eq $templateName } | Select-Object -First 1
        if ($SiteSetupRoot -eq $null) {
            $moduleName =  $ModuleSettingsRoot.Name
            $SiteSetupRoot = New-Item -ItemType $siteSetupRootPath -Path $ModuleSettingsRoot.Paths.Path -Name "$siteSetupRootNamePrefix$moduleName Site Setup" | Wrap-Item
            $SiteSetupRoot.__Name = $moduleName
        }
        $SiteSetupRoot | Wrap-Item
    }

    end {
        Write-Verbose "Cmdlet Get-SiteSetupForModule - End"
    }
}