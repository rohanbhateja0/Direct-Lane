function Show-AddSiteLanguageDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site
    )

    begin {
        Write-Verbose "Cmdlet Show-AddSiteLanguageDialog - Begin"
    }

    process {
        Write-Verbose "Cmdlet Show-AddSiteLanguageDialog - Process"

        $targetLanguages = [ordered]@{}
        $sourceLanguages = [ordered]@{}
        Get-ChildItem -Path "/sitecore/system/languages" | ForEach-Object { 
            $lang = [Sitecore.Data.Managers.LanguageManager]::GetLanguage($_.Name)
            if($lang){
                $displayName = $lang.GetDisplayName()
                $targetLanguages[$displayName] = $_.Name
            }
        } > $null
        $Site.Languages | ? { $Site.Versions.GetLatestVersion($_).Versions.Count -gt 0 } | ForEach-Object {
            $displayName = $_.GetDisplayName()
            $sourceLanguages[$displayName] = $_.Name
        } > $null

        $result = Read-Variable -Parameters `
        @{ Name = "sourceLanguage"; Options = $sourceLanguages; Value = "en"; Title = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::AddSiteLanguageDialogSourceLanguage)); }, `
        @{ Name = "targetLanguage"; Options = $targetLanguages; Value = "en"; Title = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::AddSiteLanguageDialogTargetLanguage)); } `
            -Description $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::AddSiteLanguageDialogDescription)) `
            -Title $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::AddSiteLanguageDialogTitle)) -Width 500 -Height 600 `
            -OkButtonName $([Sitecore.Globalization.Translate]::Text("Ok")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) `

        if ($result -ne "ok") {
            Close-Window
            Exit
        }

        @{
            SourceLanguage  = $sourceLanguage
            TargetLanguage = $targetLanguage
        }
    }

    end {
        Write-Verbose "Cmdlet Show-AddSiteLanguageDialog - End"
    }
}