Import-Function Validate-PowerShell

Test-PowerShell

Try
{
    $ctx = Get-Item .
    
    Import-Function Add-SiteLanguage
    Import-Function Show-AddSiteLanguageDialog
    
    $result = Show-AddSiteLanguageDialog $ctx
    
    Add-SiteLanguage $ctx $result.SourceLanguage $result.TargetLanguage > $null
}
Catch
{
    $ErrorRecord=$Error[0]
    Write-Log -Log Error $ErrorRecord
    Show-Alert "Something went wrong. See SPE logs for more details."
    Close-Window
}