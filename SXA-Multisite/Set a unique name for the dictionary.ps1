Import-Function Get-DictionaryItem

function Invoke-ModuleScriptBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$TenantTemplates		
    )

    begin {
        Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Begin"
    }

    process {
        Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Process"
        Write-Verbose "My site: $($Site.Paths.Path)"
        Write-Verbose "My tenant templates: $($TenantTemplates | %{$_.ID})"

        $dictionary = Get-DictionaryItem $Site
        if ($dictionary) {
            $dictionary.Editing.BeginEdit()
            $dictionary.Name = ([guid]::NewGuid().ToString("N"))
            $dictionary."__Display Name" = "Dictionary"
            $dictionary.Editing.EndEdit() > $null            
        }
    }

    end {
        Write-Verbose "Cmdlet Invoke-ModuleScriptBody - End"
    }
}