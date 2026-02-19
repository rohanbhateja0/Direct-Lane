function Test-HasPostDeleteStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item]$Module
    )

    begin {
        Write-Verbose "Cmdlet Test-HasPostDeleteStep - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-HasPostDeleteStep - Process"   
        $actions = Get-ChildItem -Path $Module.Paths.Path -Recurse | ? { $_.TemplateName -eq "PostDeleteStep" } 
        $actions.Count -gt 0
    } 

    end {
        Write-Verbose "Cmdlet Test-HasPostDeleteStep - End"
    }
}