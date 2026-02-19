function Invoke-Validation {
    [CmdletBinding()]
    param(
        $Site,
        $Tenant,
        $SiteSetup,
        $TenantSetup
    )
    begin {
        Write-Verbose "Cmdlet Invoke-Validation - Begin"
    }
    process {
        Write-Verbose "Cmdlet Invoke-Validation - Process"
        $msg1 = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InstallModuleDependenciesDescription)
        $msgConfirm = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InstallModuleDependenciesPrompt)

        $tenantTextLoc = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteCollection)
        $siteTextLoc = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Site)

        $depsTextLoc = New-Object System.Collections.ArrayList($null)
        if ($SiteSetup.Count -gt 0) {
            $SiteSetup | % {
                $moduleName = $_.Fields[[Sitecore.XA.Foundation.Scaffolding.Templates+_Name+Fields]::Name]
                $depsTextLoc.Add("- $moduleName [<b>$($Site.Name)</b> $siteTextLoc]") | Out-Null
            }
        }
        if ($TenantSetup.Count -gt 0) {
            $TenantSetup | % {
                $moduleName = $_.Fields[[Sitecore.XA.Foundation.Scaffolding.Templates+_Name+Fields]::Name]
                $depsTextLoc.Add("- $moduleName [<b>$($Tenant.Name)</b> $tenantTextLoc]") | Out-Null
            }
        }
        $msg2 = $depsTextLoc -join "`n"

        $dialogParmeters = @()
        $dialogParmeters += @{ Name = "Info0"; Title = ""; Value = "<font size='3'>$msg1<br>$msg2</font>"; editor = "info" }
        $dialogParmeters += @{ Name = "Info1"; Title = ""; Value = "<font size='3'>$msgConfirm</font>"; editor = "info" }
        $dialogResult = Read-Variable -Parameters $dialogParmeters `
            -Description " " `
            -Width 690 -Height 50 `
            -Title ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InstallModuleDependenciesTitle)) `
            -OkButtonName $([Sitecore.Globalization.Translate]::Text("Yes")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("No"))
        $dialogResult -eq "ok"
    }
    end {
        Write-Verbose "Cmdlet Invoke-Validation - End"
    }
}

function Install-DependenciesForSiteModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$SiteSetupItem
    )

    begin {
        Write-Verbose "Cmdlet Install-DependenciesForSiteModule - Begin"
        Import-Function Get-TenantItem
        Import-Function Add-SiteModule
        Import-Function Add-TenantModule
        Import-Function Get-ModuleActionItem
        Import-Function Test-ItemIsSiteSetup
        Import-Function Get-MissingSiteSetupDependency
    }

    process {
        Write-Verbose "Cmdlet Install-DependenciesForSiteModule - Process"
        $tenant = Get-TenantItem $Site
        $invokedSiteActions = Get-ModuleActionItem $Site
        $invokedTenantActions = Get-ModuleActionItem $tenant
        $invokedActions = $invokedTenantActions + $invokedSiteActions

        $dependentSetups = Get-MissingSiteSetupDependency $SiteSetupItem $invokedActions | ? { $_.ID -ne $SiteSetupItem.ID } | Wrap-Item
        if ($dependentSetups.Count -gt 0) {
            $tenantSetups = $dependentSetups | ? { (Test-ItemIsSiteSetup $_) -eq $false }
            $siteSetups = $dependentSetups | ? { Test-ItemIsSiteSetup $_ }
            $validation = Invoke-Validation $Site $tenant $siteSetups $tenantSetups
            if ($validation) {
                if($tenantSetups){
                    Add-TenantModule $tenant $tenantSetups
                }
                if($siteSetups){
                    Add-SiteModule $Site $siteSetups
                }
            }
            $validation
        }
    }

    end {
        Write-Verbose "Cmdlet Install-DependenciesForSiteModule - End"
    }
}