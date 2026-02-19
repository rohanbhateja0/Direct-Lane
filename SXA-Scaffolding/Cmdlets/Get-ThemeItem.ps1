function Get-ThemeItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentItem,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Sitecore.Data.Items.DeviceItem]$DeviceItem
    )

    begin {
        Write-Verbose "Cmdlet Get-ThemeItem - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-ThemeItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Theming.IThemingContext]).GetThemeItem($CurrentItem, $DeviceItem) | ? { $_ -ne $null} | Wrap-Item    
    }

    end {
        Write-Verbose "Cmdlet Get-ThemeItem - End"
    }
}