Import-Function Get-FieldSourceMapping
Import-Function Get-FieldWithEmptySourceField

$mapping = Get-FieldSourceMapping
foreach ($item in $selectedData) {
    $item.Editing.BeginEdit()
    $item.Fields["Source"].Value = $mapping[$item."Type"]
    $item.Editing.EndEdit() > $null
}


Get-FieldWithEmptySourceField $actionData | Update-ListView -InfoTitle "" `
    -Property `
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Name); Expression = {$_.Name} },
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Path); Expression = {$_.Paths.Path } },
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Type); Expression = {$_.Fields["Type"].Value} },
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Recommendation); Expression = {$mapping[$_.Fields["Type"].Value]} }