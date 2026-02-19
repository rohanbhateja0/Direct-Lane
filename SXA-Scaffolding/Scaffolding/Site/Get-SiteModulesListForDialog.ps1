function Get-SiteModulesListForDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteItem
    )

    begin {
        Write-Verbose "Cmdlet Geat-SiteModulesListForDialog - Begin"
        Import-Function Get-RootSetupTemplateName
        Import-Function Get-ModuleDefinition
        Import-Function Get-OrderedDictionaryByKey
        Import-Function Get-ValidSiteSetupDefinition
    }

    process {
        Write-Verbose "Cmdlet Get-SiteModulesListForDialog - Process"
        $dialogOptions = New-Object System.Collections.Specialized.OrderedDictionary
        $siteSetupRootTemplateName = Get-RootSetupTemplateName $SiteItem
        [Item[]]$allDefinitions = Get-ModuleDefinition "*" $siteSetupRootTemplateName
        $allDefinitions = Get-ValidSiteSetupDefinition $SiteItem $allDefinitions
        $nonSystemDefinitions = $allDefinitions | ? { $_ -ne $null } | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IsSystemModule']).Checked -eq $false } | ? { $_.IncludeIfInstalled.Length -eq 0 }
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
        Write-Verbose "Cmdlet Get-SiteModulesListForDialog - End"
    }
}