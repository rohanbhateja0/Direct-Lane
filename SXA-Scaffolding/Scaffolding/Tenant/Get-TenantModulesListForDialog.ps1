function Get-TenantModulesListForDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantItem
    )

    begin {
        Write-Verbose "Cmdlet Get-TenantModulesListForDialog - Begin"
        Import-Function Get-ModuleDefinition
        Import-Function Get-RootSetupTemplateName
        Import-Function Get-OrderedDictionaryByKey
    }

    process {
        Write-Verbose "Cmdlet Get-TenantModulesListForDialog - Process"
        $dialogOptions = New-Object System.Collections.Specialized.OrderedDictionary
        $tenantSetupRootTemplateName = Get-RootSetupTemplateName $TenantItem
        [Item[]]$allDefinitions = Get-ModuleDefinition * $tenantSetupRootTemplateName
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
        $dialogOptions        
    }

    end {
        Write-Verbose "Cmdlet Get-TenantModulesListForDialog - End"
    }
}