function Invoke-PreDeleteStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$DefinitionItems,
        [Parameter(Mandatory = $true, Position = 1 )]
        $Model
    )
    
    begin {
        Write-Verbose "Cmdlet Invoke-PreDeleteStep - Begin"
    }
    
    process {
        Write-Verbose "Cmdlet Invoke-PreDeleteStep - Process"
        $DefinitionItems | ? {
            $actions = Get-ChildItem -Path $_.Paths.Path -Recurse | ? { $_.TemplateName -eq "PreDeleteStep" } 
            $actions | % {
                $script = Get-Item -Path . -ID $_.Script
                Invoke-Script $script
                try {
                    Invoke-Step $Model > $null
                }
                catch [System.Exception] {
                    Write-Error $_
                }        
            }    
        }
    }
    
    end {
        Write-Verbose "Cmdlet Invoke-PreDeleteStep - End"
    }
}