function Test-HasPreDeleteStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item]$Module
    )

    begin {
        Write-Verbose "Cmdlet Test-HasPreDeleteStep - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-HasPreDeleteStep - Process"   
        $actions = Get-ChildItem -Path $Module.Paths.Path -Recurse | ? { $_.TemplateName -eq "PreDeleteStep" } 
        $actions.Count -gt 0
    } 

    end {
        Write-Verbose "Cmdlet Test-HasPreDeleteStep - End"
    }
}