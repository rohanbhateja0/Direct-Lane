function Set-CreativeExchangeFileStorageReference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1 )]
        [string]$newSiteName
    )

    begin {
        Write-Verbose "Cmdlet Set-CreativeExchangeFileStorageReference - Begin"
        Import-Function Get-SettingsItem
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Set-CreativeExchangeFileStorageReference - Process"
        
        $settingsItem = Get-SettingsItem $Site
        $creativeExchangeStoragesFolderTemplateId = "{0D792404-79AA-483D-BB0C-50785F2E295B}"
        $creativeExchangeFileStorageTemplateId = "{BCA27DE4-A869-4282-B3FB-4FBD7BA1B87B}"
        $creativeExchangeStoragesFolderItem = $settingsItem.Children | Select-InheritingFrom $creativeExchangeStoragesFolderTemplateId | Select-Object -First 1
        if ($creativeExchangeStoragesFolderItem) {
            $creativeExchangeFileStorage = $creativeExchangeStoragesFolderItem.Children | Select-InheritingFrom $creativeExchangeFileStorageTemplateId | Select-Object -First 1 | Wrap-Item
            $folder = "`$(creativeExchangeFolder)/FileStorage/$newSiteName"
            Write-Verbose "Set creative exchange file storage destination folder to '$folder'"
            $creativeExchangeFileStorage."Destination Path" = $folder
        }
        else {
            Write-Verbose "Creative Exchange folder cannot be found. Skipping 'Set-CreativeExchangeFileStorageReference'"
        }
    }

    end {
        Write-Verbose "Cmdlet Set-CreativeExchangeFileStorageReference - End"
    }
}