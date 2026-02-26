Import-Function Validate-PowerShell

Test-PowerShell

Try
{
    $ctx = gi .
    Import-Function New-Site
    $siteLocation = Get-Item -Path  "/sitecore/content/CBRE/Brands"
    
    $model = Show-NewSiteDialog $siteLocation
    
    Write-Host "=== Model Properties ===" -ForegroundColor Cyan
    Write-Host "SiteName: $($model.SiteName)" -ForegroundColor Yellow
    Write-Host "SiteLocation: $($model.SiteLocation.Paths.Path)" -ForegroundColor Yellow
    Write-Host "CloneExistingSite: $($model.CloneExistingSite)" -ForegroundColor Yellow
    Write-Host "ExistingSite: $(if ($model.ExistingSite) { $model.ExistingSite.Paths.Path } else { 'null' })" -ForegroundColor Yellow
    Write-Host "DefinitionItems Count: $($model.DefinitionItems.Count)" -ForegroundColor Yellow
    Write-Host "CreateSiteTheme: $($model.CreateSiteTheme)" -ForegroundColor Yellow
    Write-Host "ThemeName: $($model.ThemeName)" -ForegroundColor Yellow
    Write-Host "ValidThemes Count: $(if ($model.ValidThemes) { $model.ValidThemes.Count } else { 0 })" -ForegroundColor Yellow
    Write-Host "Language: $($model.Language)" -ForegroundColor Yellow
    Write-Host "HostName: $($model.HostName)" -ForegroundColor Yellow
    Write-Host "VirtualFolder: $($model.VirtualFolder)" -ForegroundColor Yellow
    Write-Host "GridSetup: $(if ($model.GridSetup) { $model.GridSetup.Paths.Path } else { 'null' })" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    New-Site $model
}
Catch
{
    $ErrorRecord=$Error[0]
    Write-Log -Log Error $ErrorRecord
    Show-Alert "Something went wrong. See SPE logs for more details."
    Close-Window
}



