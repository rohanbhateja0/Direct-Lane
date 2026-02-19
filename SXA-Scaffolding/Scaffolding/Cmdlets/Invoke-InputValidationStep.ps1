function Invoke-InputValidationStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$DefinitionItems,
        [Parameter(Mandatory = $true, Position = 1 )]
        $Model
    )
    
    begin {
        Write-Verbose "Cmdlet Invoke-InputValidationStep - Begin"
    }
    
    process {
        Write-Verbose "Cmdlet Invoke-InputValidationStep - Process"
        $result = $true
        $DefinitionItems | % {
            $actions = Get-ChildItem -Path $_.Paths.Path -Recurse | ? { $_.TemplateName -eq "InputValidationStep" } 
            $actions | % {
                $script = Get-Item -Path . -ID $_.ValidationScript
                Write-Verbose "Processing: $($script.Paths.path)"
                Invoke-Script $script
                try {
                    [bool]$validatorResult = Invoke-Validation $Model
                    $result = $validatorResult -and $result
                }
                catch [System.Exception] {
                    Write-Error $_
                }        
            }    
        }
        $result
    }
    
    end {
        Write-Verbose "Cmdlet Invoke-InputValidationStep - End"
    }
}