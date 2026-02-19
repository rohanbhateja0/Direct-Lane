function Get-FolderForModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$CurrentItem,
        [Parameter(Mandatory = $true, Position = 1 )]
        [String]$KeyOut
    )

    begin {
        Write-Verbose "Cmdlet Get-FolderForModule - Begin"
        Import-Function Get-ModuleStartLocation
    }

    process {
        Write-Verbose "Cmdlet Get-FolderForModule - Process"
        $availableContainers = Get-ModuleStartLocation
        $itemPath = $CurrentItem.Paths.Path
        $CurrentItemContainerKey = $availableContainers.Keys | ? { $itemPath -like ($availableContainers[$_] -f "*") } | Select-Object -First 1
        $startPath = $availableContainers[$CurrentItemContainerKey]
        
        $temp = $itemPath.TrimStart($startPath)
        $layer = $temp.Substring(0, $temp.IndexOf("/"))

        $replacement = $startPath -f $layer
        
        $path = $availableContainers[$KeyOut] -f $layer + $CurrentItem.Paths.Path.TrimEnd("/").Replace($replacement, "")
        $item = $CurrentItem.Database.GetItem($path)
        if ($item) {
            $item | Wrap-Item
        }        
    }

    end {
        Write-Verbose "Cmdlet Get-FolderForModule - End"
    }
}