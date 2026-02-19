function Get-ValidSiteSetupDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteLocation,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Get-ValidSiteSetupDefinition - Begin"
        Import-Function Get-TenantTemplatesRoot
        Import-Function Get-TenantTemplate
        Import-Function Get-InvokedTenantAction
    }

    process {
        Write-Verbose "Cmdlet Get-ValidSiteSetupDefinition - Process"
        $TenantTemplates = Get-TenantTemplate (Get-TenantTemplatesRoot  $SiteLocation)
        $InvokedTenantAction = Get-InvokedTenantAction $TenantTemplates $SiteLocation
        $InvokedTenantActionIDs = $InvokedTenantAction | % {$_.ID.ToString()}
        $DefinitionItems | % {
            if ($_.Dependencies -eq "") {
                $_
            }
            else {
                $dependentModules = $_.Dependencies.Split("|") | ? { [guid]::TryParse($_, [ref][guid]::Empty) }
                $moduleValid = $true;
                $dependentModules | % {
                    $dependentAction = Get-Item -Path master: -ID $_

                    # Check wheter is SiteSetup
                    $setup = [Sitecore.XA.Foundation.SitecoreExtensions.Extensions.ItemExtensions]::GetParentOfTemplate($dependentAction, @("{292CCFCD-7790-4692-856B-76014B8038E7}","{BED31D6F-D968-45A9-B54E-12D7F977D861}"))
                    if ($setup -eq $null) {
                        if ($InvokedTenantActionIDs.Contains($dependentAction.ID.ToString())) {
                            # OK
                        }
                        else {
                            $moduleValid = $false
                        }
                    }
                }
                if ($moduleValid ) {
                    $_
                }
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Get-ValidSiteSetupDefinition - End"
    }
}