Import-Function Validate-PowerShell
Import-Function Write-HostWithTimestamp

Test-PowerShell

Try
{
    $startTime = [DateTime]::Now
    
    # Write header to SPE log
    $logHeader = @"
========================================
Site Creation Log
Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))
========================================
"@
    Write-Log -Log Info -Message $logHeader
    Write-HostWithTimestamp "Site creation started - logging to SPE log file" -ForegroundColor Cyan
    $ctx = gi .
    Import-Function New-CBRESite
    $siteLocation = Get-Item -Path  "/sitecore/content/CBRE/Brands"
    
    $model = Show-CBRENewSiteDialog $siteLocation
    
    Write-HostWithTimestamp "=== Model Properties ===" -ForegroundColor Cyan
    Write-HostWithTimestamp "SiteName: $($model.SiteName)" -ForegroundColor Yellow
    Write-HostWithTimestamp "SiteLocation: $($model.SiteLocation.Paths.Path)" -ForegroundColor Yellow
    Write-HostWithTimestamp "CloneExistingSite: $($model.CloneExistingSite)" -ForegroundColor Yellow
    Write-HostWithTimestamp "ExistingSite: $(if ($model.ExistingSite) { $model.ExistingSite.Paths.Path } else { 'null' })" -ForegroundColor Yellow
    Write-HostWithTimestamp "DefinitionItems Count: $($model.DefinitionItems.Count)" -ForegroundColor Yellow
    Write-HostWithTimestamp "CreateSiteTheme: $($model.CreateSiteTheme)" -ForegroundColor Yellow
    Write-HostWithTimestamp "ThemeName: $($model.ThemeName)" -ForegroundColor Yellow
    Write-HostWithTimestamp "ValidThemes Count: $(if ($model.ValidThemes) { $model.ValidThemes.Count } else { 0 })" -ForegroundColor Yellow
    Write-HostWithTimestamp "Language: $($model.Language)" -ForegroundColor Yellow
    Write-HostWithTimestamp "HostName: $($model.HostName)" -ForegroundColor Yellow
    Write-HostWithTimestamp "VirtualFolder: $($model.VirtualFolder)" -ForegroundColor Yellow
    Write-HostWithTimestamp "GridSetup: $(if ($model.GridSetup) { $model.GridSetup.Paths.Path } else { 'null' })" -ForegroundColor Yellow
    Write-HostWithTimestamp "========================" -ForegroundColor Cyan
    
    New-CBRESite $model
    
    $endTime = [DateTime]::Now
    $duration = $endTime - $startTime
    Write-HostWithTimestamp "=== Site Creation Completed ===" -ForegroundColor Green
    Write-HostWithTimestamp "Total Duration: $($duration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
    
    # Write footer to SPE log
    $logFooter = @"
========================================
Site Creation Completed
Ended: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))
Total Duration: $($duration.TotalSeconds.ToString('F2')) seconds
========================================
"@
    Write-Log -Log Info -Message $logFooter
    Write-HostWithTimestamp "`nAll log entries have been written to the SPE log file." -ForegroundColor Green
    Write-HostWithTimestamp "You can view the logs in Sitecore PowerShell Extension logs." -ForegroundColor Cyan
}
Catch
{
    $ErrorRecord=$Error[0]
    Write-Log -Log Error $ErrorRecord
    Show-Alert "Something went wrong. See SPE logs for more details."
    Close-Window
}



