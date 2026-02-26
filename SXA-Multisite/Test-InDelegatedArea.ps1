function Test-InDelegatedArea {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Item
    )

    begin {
        Write-Verbose "Cmdlet Test-InDelegatedArea - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-InDelegatedArea - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Multisite.Services.IDelegatedAreaService]).CheckForDelegatedArea($Item)
    }

    end {
        Write-Verbose "Cmdlet Test-InDelegatedArea - End"
    }
}