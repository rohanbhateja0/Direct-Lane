function Get-SettingsFolderForFeature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$RenderingsFolder
    )

    begin {
        Write-Verbose "Cmdlet Get-SettingsFolderForFeature - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-SettingsFolderForFeature - Process"
        $path = "/sitecore/system/settings/Feature/" + $RenderingsFolder.Paths.Path.TrimEnd("/").Replace("/sitecore/layout/Renderings/Feature", "")
        $item = $RenderingsFolder.Database.GetItem($path)
        if ($item) {
            $item | Wrap-Item
        }        
    }

    end {
        Write-Verbose "Cmdlet Get-SettingsFolderForFeature - End"
    }
}