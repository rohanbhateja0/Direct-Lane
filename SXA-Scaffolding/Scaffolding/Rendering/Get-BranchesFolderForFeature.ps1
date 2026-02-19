function Get-BranchesFolderForFeature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$RenderingsFolder
    )

    begin {
        Write-Verbose "Cmdlet Get-BranchesFolderForFeature - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-BranchesFolderForFeature - Process"
        $path = "/sitecore/templates/Branches/Feature/" + $RenderingsFolder.Paths.Path.TrimEnd("/").Replace("/sitecore/layout/Renderings/Feature", "")
        $item = $RenderingsFolder.Database.GetItem($path)
        if ($item) {
            $item | Wrap-Item
        }
    }

    end {
        Write-Verbose "Cmdlet Get-BranchesFolderForFeature - End"
    }
}
