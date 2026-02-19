function Test-ActionIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,
            
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems,

        [Parameter(Mandatory = $false, Position = 2 )]
        [Item[]]$InvokedActions
    )

    begin {
        Write-Verbose "Cmdlet Test-ActionIntegrity - Begin"
        Import-Function Get-Action
    }

    process {
        Write-Verbose "Processing $($Site.Name) site"
        if($InvokedActions -eq $null){
            $true
        }else{
            $invokedActionsIDs = $InvokedActions.ID
    
            $missingDependencies = $DefinitionItems | ? {
                $scaffoldingSetupItem = $_
                [Sitecore.Data.ID[]]$dependencies = $scaffoldingSetupItem.Dependencies.Split('|') | ? { [guid]::TryParse($_, [ref][guid]::Empty) }
                if ($dependencies.Count -gt 0) {
                    $missingActions = $dependencies | ? { -not($invokedActionsIDs.Contains($_)) }
                    if ($missingActions) {
                        Write-Verbose "Could not install, missing action"
                        $missingActions | % { Write-Verbose $_ }
                        $true
                    }
                    else {
                        Write-Verbose "Dependencies OK"
                        $false
                    }
                } 
            }
            $missingDependencies.Count -eq 0
        }
    }

    end {
        Write-Verbose "Cmdlet Test-ActionIntegrity - End"
    }
}