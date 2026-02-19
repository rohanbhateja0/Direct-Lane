function Get-PresentationItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentItem
    )

    begin {
        Write-Verbose "Cmdlet Get-PresentationItem - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-PresentationItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Presentation.IPresentationContext]).GetPresentationItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item      
    }

    end {
        Write-Verbose "Cmdlet Get-PresentationItem - End"
    }
}