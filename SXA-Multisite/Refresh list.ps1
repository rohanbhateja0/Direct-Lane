Import-Function Get-FieldWithEmptySourceField
Import-Function Get-FieldSourceMapping

$items = Get-FieldWithEmptySourceField $actionData
$mapping = Get-FieldSourceMapping
$items | Update-ListView -InfoTitle "" `
    -Property `
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Name); Expression = {$_.Name} },
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Path); Expression = {$_.Paths.Path } },
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Type); Expression = {$_.Fields["Type"].Value} },
        @{Label = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::Recommendation); Expression = {$mapping[$_.Fields["Type"].Value]} }