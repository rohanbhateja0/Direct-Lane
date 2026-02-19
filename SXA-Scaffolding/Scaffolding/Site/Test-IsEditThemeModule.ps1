function Test-IsEditThemeModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item]$module
    )
    
    begin {
        Write-Verbose "Cmdlet Test-IsEditThemeModule - Begin"
        Import-Function Get-Action
    }
    
    process {
        Write-Verbose "Cmdlet Test-IsEditThemeModule - Process"
        $actions = $module | Get-Action | ? { ($_.TemplateName -eq "EditSiteTheme") -or ($_.TemplateName -eq "ExtendSiteTheme") }
        $actions.Count -gt 0
    }
    
    end {
        Write-Verbose "Cmdlet Test-IsEditThemeModule - End"
    }
}