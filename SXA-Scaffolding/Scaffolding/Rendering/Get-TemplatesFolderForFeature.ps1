function Get-TemplatesFolderForFeature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$RenderingsFolder
    )

    begin {
        Write-Verbose "Cmdlet Get-TemplatesFolderForFeature - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-TemplatesFolderForFeature - Process"
        $path = "/sitecore/templates/Feature/" + $RenderingsFolder.Paths.Path.TrimEnd("/").Replace("/sitecore/layout/Renderings/Feature", "")
        $item = $RenderingsFolder.Database.GetItem($path)
        if ($item) {
            $item | Wrap-Item
        }
    }

    end {
        Write-Verbose "Cmdlet Get-TemplatesFolderForFeature - End"
    }
}
