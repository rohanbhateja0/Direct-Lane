function Test-ModuleContainsRoots {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TargetModule,
        [Parameter(Mandatory = $true, Position = 1 )]
        [string[]]$Roots
    )

    begin {
        Write-Verbose "Cmdlet Test-ModuleContainsRoots - Begin"
        Import-Function Get-ModuleStartLocation
        Import-Function Get-FolderForModule
    }

    process {
        Write-Verbose "Cmdlet Test-ModuleContainsRoots - Process"
        $locs = Get-ModuleStartLocation
        
        $missing = $locs.Keys | `
            ? { $Roots.Contains($_) } | `
            ? { (Get-FolderForModule $TargetModule $_) -eq $null }
            
        $missing.Count -eq 0
    }

    end {
        Write-Verbose "Cmdlet Test-ModuleContainsRoots - End"
    }
}