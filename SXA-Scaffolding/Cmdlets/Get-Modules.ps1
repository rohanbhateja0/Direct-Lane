function Get-Modules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentItem
    )

    begin {
        Write-Verbose "Cmdlet Get-Modules - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-Modules - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Scaffolding.Services.IScaffoldingService]).GetModules($CurrentItem)
    }

    end {
        Write-Verbose "Cmdlet Get-Modules - End"
    }
}