function Test-ModuleEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentItem,
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$FeatureItem        
    )

    begin {
        Write-Verbose "Cmdlet Test-ModuleEnabled - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-ModuleEnabled - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Scaffolding.Services.IScaffoldingService]).IsModuleEnabled($CurrentItem, $FeatureItem)
    }

    end {
        Write-Verbose "Cmdlet Test-ModuleEnabled - End"
    }
}