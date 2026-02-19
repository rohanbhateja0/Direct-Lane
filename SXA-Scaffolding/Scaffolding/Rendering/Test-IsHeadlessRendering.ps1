function Test-IsHeadlessRendering() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]$renderingType
    )
    
    begin {
      Write-Verbose "Cmdlet Test-IsHeadlessRendering - Begin"
    }

    process {
      Write-Verbose "Cmdlet Test-IsHeadlessRendering - Process"
      
      $renderingType -eq [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::JavaScriptRendering -or $renderingType -eq [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::JsonRendering
    }

    end {
      Write-Verbose "Cmdlet Test-IsHeadlessRendering - End"
    }
}