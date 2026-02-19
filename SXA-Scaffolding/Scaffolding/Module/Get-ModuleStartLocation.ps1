function Get-ModuleStartLocation {
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "Cmdlet Get-ModuleStartLocation - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-ModuleStartLocation - Process"
        $result = New-Object System.Collections.Specialized.OrderedDictionary
        $result.Add("Templates", "/sitecore/templates/{0}")
        $result.Add("Branches", "/sitecore/templates/Branches/{0}")
        $result.Add("Settings", "/sitecore/system/Settings/{0}")
        $result.Add("Renderings", "/sitecore/layout/Renderings/{0}")
        $result.Add("Placeholder Settings", "/sitecore/layout/Placeholder Settings/{0}")
        $result.Add("Layouts", "/sitecore/layout/Layouts/{0}")
        $result.Add("Media Library", "/sitecore/media library/{0}") 
        $result
    }

    end {
        Write-Verbose "Cmdlet Get-ModuleStartLocation - End"
    }
}