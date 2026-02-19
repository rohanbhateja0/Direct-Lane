function Get-ModuleRootCandidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentItem
    )

    begin {
        Write-Verbose "Cmdlet Get-ModuleRootCandidate - Begin"
        Import-Function Get-ModuleStartLocation
        Import-Function Get-FolderForModule
    }

    process {
        Write-Verbose "Cmdlet Get-ModuleRootCandidate - Process"
        $locs = Get-ModuleStartLocation
        
        $candidates = @()

        $itemPath = $CurrentItem.Paths.Path
        $key = $locs.Keys | ? { $itemPath -like ($locs[$_] -f "*") } | Select-Object -First 1
        
        $startPath = ($locs[$key] -f "").TrimEnd("/")
        $loopFinishPatternpattern = "^$startPath/(Feature|Foundation|Project)$"
        
        $parent = $CurrentItem
        $result = $null
        while (($parent.Paths.Path -match $loopFinishPatternpattern -eq $false) -and $result -eq $null -and $parent -ne $null) {
            Write-Verbose "Checking $($parent.Paths.Path)"
            $missing = $locs.Keys | ? { (Get-FolderForModule $parent $_) -eq $null }
            Write-Verbose "`tScore: $($missing.Count)"  
            $candidates += @{ Score = $missing.Count; Item = $parent; }

            # perfect hit
            if ($missing.Count -eq 0) {
                Write-Verbose "Found module root"
                $result = $parent                
            }            
            $parent = $parent.Parent
        }

        # get the best candidate based on score
        if ($result -eq $null) {
            [array]::Reverse($candidates)
            $result = $candidates | Sort-Object @{Expression = {$_.Score}} | Select-Object -First 1 | % { $_.Item }
        }
        $result
    }

    end {
        Write-Verbose "Cmdlet Get-ModuleRootCandidate - End"
    }
}