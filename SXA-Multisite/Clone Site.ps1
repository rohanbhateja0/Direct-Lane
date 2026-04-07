Import-Function Validate-PowerShell
Import-Function Run-SiteManager
Import-Function Get-DictionaryItem

Test-PowerShell

Try
{
    $ctx = Get-Item "/sitecore/content/CBRE/Template/Site Template"
    
    Import-Function Copy-CBRESite
    Import-Function Show-CloneSiteDialog
    
    $dialogResult = Show-CloneSiteDialog $ctx
    $cloneSiteName = $dialogResult.siteName
    $mapping = $dialogResult.siteDefinitionmapping
    $location = $dialogResult.siteLocation
    
    $destinationSite = Copy-CBRESite $ctx $location $cloneSiteName $mapping
    $destinationSiteID = $destinationSite.ID.ToString()
    
    $dictionary = Get-DictionaryItem $destinationSite
    if ($dictionary) {
        Rename-Item -Path $dictionary.Paths.Path -NewName ([guid]::NewGuid().ToString("N"))
        $dictionary."__Display Name" = "Dictionary"
    }
    $host.PrivateData.CloseMessages.Add("item:load(id=$destinationSiteID)")

    Run-SiteManager
}
Catch
{
    $ErrorRecord=$Error[0]
    Write-Log -Log Error $ErrorRecord
    Show-Alert "Something went wrong. See SPE logs for more details."
    Close-Window
}