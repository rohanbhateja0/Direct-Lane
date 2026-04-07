$database = "master"
$folderPath = "/sitecore/content/CBRE/Shared/Shared Content/Home/Content/PressReleases"

$folderItem = Get-Item -Path "$database`:$folderPath"

if ($null -eq $folderItem) {
    Write-Host "Folder not found: $folderPath"
    return
}

$children = Get-ChildItem -Path $folderItem.ProviderPath

if (-not $children -or $children.Count -eq 0) {
    Write-Host "No subitems found under: $folderPath"
    return
}

$bulkUpdate = New-Object Sitecore.Data.BulkUpdateContext
$eventDisabler = New-Object Sitecore.Data.Events.EventDisabler
$securityDisabler = New-Object Sitecore.SecurityModel.SecurityDisabler

try {
    foreach ($child in $children) {
        Write-Host "Deleted: $($child.Paths.FullPath)"
        $child.Delete()
    }

    Write-Host "Completed deleting subitems under: $folderPath"
}
finally {
    if ($securityDisabler) { $securityDisabler.Dispose() }
    if ($eventDisabler) { $eventDisabler.Dispose() }
    if ($bulkUpdate) { $bulkUpdate.Dispose() }
}