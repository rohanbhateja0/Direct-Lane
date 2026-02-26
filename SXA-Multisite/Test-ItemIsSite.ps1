function Test-ItemIsSite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item]$Item
    )

    begin {
        Write-Verbose "Cmdlet Test-ItemIsSite - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-ItemIsSite - Process"
        [Sitecore.Data.ID]$baseTemplate = [Sitecore.XA.Foundation.Multisite.Templates+Site]::ID
        [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Item).InheritsFrom($baseTemplate)
    }

    end {
        Write-Verbose "Cmdlet Test-ItemIsSite - End"
    }
}