function Set-InsertOptionsForTenantTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$TenantTemplates
    )

    begin {
        Write-Verbose "Cmdlet Set-InsertOptionsForTenantTemplate - Begin"
        Import-Function Get-ProjectTemplateBasedOnBaseTemplate
    }

    process {
        Write-Verbose "Cmdlet Set-InsertOptionsForTenantTemplate - Process"

        $TenantTemplates | % { $_.Children} | ? { $_.Name -eq "__Standard Values" } | % {
            Write-Verbose "Processing SV Item $($_.Paths.Path)"
            $svItem = $_ | Wrap-Item

            [Sitecore.Data.ID[]]$insertOptions = $_.Fields['__Masters'].Value.Split('|') | ? { $_ -ne "" }
            Write-Verbose "Insert Options found: $($insertOptions)"
            $insertOptions | % {
                $iOption = $_
                Write-Verbose "Searching for candidate for Insert Option ($($iOption))"
                $candidate = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $iOption
                if($candidate.Length -gt 1){ 
                    $candidate = $candidate | Select-Object -First 1 
                    Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
                }                
                if ($candidate) {
                    Write-Verbose "Candidate found: $($candidate.Paths.Path)"
                    Write-Verbose "Changing Insert Option of item: $($svItem.Paths.Path) from $($iOption) to $($candidate.ID)"

                    $oldValue = $svItem.Fields['__Masters'].Value
                    $newValue = $oldValue.Replace($iOption, $($candidate.ID))
                    $svItem.__Masters = $newValue
                }
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Set-InsertOptionsForTenantTemplate - End"
    }
}