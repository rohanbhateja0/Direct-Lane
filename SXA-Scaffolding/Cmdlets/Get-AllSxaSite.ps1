function Get-AllSxaSite {
    [CmdletBinding()]
    param()
    
    begin {
        Write-Verbose "Cmdlet Get-AllSxaSite - Begin"
        $siteItemTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+Site]::ID
        Import-Function Get-UniqueItem
        Import-Function Select-InheritingFrom
    }
    
    process {
        Write-Verbose "Cmdlet Get-AllSxaSite - Process"   
        $database = (Get-Item .).Database
        $dbName = "master"
        if($database){
            $dbName = $database.Name 
        }
        
        $sites = [Sitecore.Sites.SiteManager]::GetSites() | `
            % { $_.Properties["rootPath"] } | `
            ? { $_ -ne $null } | `
            ? { (Test-Path $_) -eq $true } | `
            % { Get-Item -Path "$($dbName):$($_)" } | `
            ? { $_ -ne $null } | `
            Select-InheritingFrom $siteItemTemplateId
        Get-UniqueItem $sites
    } 
    
    end {
        Write-Verbose "Cmdlet Get-AllSxaSite - End"
    }
}