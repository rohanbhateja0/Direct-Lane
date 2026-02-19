function Invoke-PreDeleteValidationStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$DefinitionItems,
        [Parameter(Mandatory = $true, Position = 1 )]
        $Model
    )
    
    begin {
        Write-Verbose "Cmdlet Invoke-PreDeleteValidationStep - Begin"
    }
    
    process {
        Write-Verbose "Cmdlet Invoke-PreDeleteValidationStep - Process"
        $result = $true
        $DefinitionItems | % {
            $actions = Get-ChildItem -Path $_.Paths.Path -Recurse | ? { $_.TemplateName -eq "PreDeleteValidationStep" } 
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
        Write-Verbose "Cmdlet Invoke-PreDeleteValidationStep - End"
    }
}