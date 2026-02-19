function Get-SortedSetupItemsCollection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [System.Collections.Generic.List[Item]]$allDefinitions
    )

    begin {
        Write-Verbose "Cmdlet Get-SortedSetupItemsCollection - Begin"
        Import-Function Get-Action
    }

    process {
        Write-Verbose "Cmdlet Get-SortedSetupItemsCollection - Process"
        [System.Collections.Generic.List[Item]]$result = @()
        if ($allDefinitions) {
            $allDefinitions | ? { $_.Dependencies -eq ""} | % { $result.Add($_) }
            $result | % { $allDefinitions.Remove($_) } > $null

            $index = 2
            while ($index -gt 0) {
                [Item[]]$allActions = $allDefinitions | % { Get-Action $_ }
                $modulesWithSolvedDependencies = $allDefinitions | ? {
                    [Sitecore.Data.ID[]]$currentDefinitionDependencies = $_.Dependencies.Split('|') | ? { [guid]::TryParse($_, [ref][guid]::Empty) }
                    $dependenciesSolved = $true
                    foreach ($dep in $currentDefinitionDependencies) {
                        [Sitecore.Data.ID[]]$ids = $allActions.ID
                        if ($ids.Contains($dep) -eq $true) {
                            $dependenciesSolved = $false
                        }
                    }
                    $dependenciesSolved
                    if ($dependenciesSolved -eq $true) {
                        $index = 2
                    }
                }

                $modulesWithSolvedDependencies | % {
                    $result.Add($_)
                    $allDefinitions.Remove($_)
                } > $null

                $index-- > $null
            }

            if ($allDefinitions.Count -gt 0) {
                Write-Error "Circular Dependency found: "
                $allDefinitions | ForEach-Object { Write-Error "$($_.ID)" }
            }
        }
        return ,$result
    }

    end {
        Write-Verbose "Cmdlet Get-SortedSetupItemsCollection - End"
    }
}