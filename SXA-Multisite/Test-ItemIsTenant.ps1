function Test-ItemIsTenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item]$Item
    )

    begin {
        Write-Verbose "Cmdlet Test-ItemIsTenant - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-ItemIsTenant - Process"
        [Sitecore.Data.ID]$baseTemplate = [Sitecore.XA.Foundation.Multisite.Templates+_BaseTenant]::ID
        [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Item).InheritsFrom($baseTemplate)
    }

    end {
        Write-Verbose "Cmdlet Test-ItemIsTenant - End"
    }
}