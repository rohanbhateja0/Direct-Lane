function Get-RenderingRenderingParameterTemplateItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$RenderingItem
    )

    begin {
        Write-Verbose "Cmdlet Get-RenderingRenderingParameterTemplateItem - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-RenderingRenderingParameterTemplateItem - Process"
        $RenderingItem = $RenderingItem | Wrap-Item
        $renderingParametersItemPath = $RenderingItem."Parameters Template"
        if ($renderingParametersItemPath) {
            $RenderingItem.Database.GetItem($renderingParametersItemPath)
        }
    }

    end {
        Write-Verbose "Cmdlet Get-RenderingRenderingParameterTemplateItem - End"
    }
}
