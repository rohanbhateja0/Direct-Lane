function New-MappingString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [System.Collections.Hashtable]$hashTable
    )

    begin {
        Write-Verbose "Cmdlet New-MappingString - Begin"
    }

    process {
        Write-Verbose "Cmdlet New-MappingString - Process"
        $obj = New-Object "Sitecore.Text.UrlString"
        $hashTable.GetEnumerator() | ForEach-Object {
            $obj[$_.Name] = $_.Value
        }
        [System.Web.HttpUtility]::UrlEncode($obj.ToString())
    }

    end {
        Write-Verbose "Cmdlet New-MappingString - End"
    }
}