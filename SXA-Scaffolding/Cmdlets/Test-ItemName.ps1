function Test-ItemName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$itemName
    )

    begin {
        Write-Verbose "Cmdlet Test-ItemName - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-ItemName - Process"
        $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
        if ($itemName.Length -gt 100) {
            $errorMessage = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
            @{ "result" = $false; "message" = $errorMessage }
            return;
        }
        if ([System.Text.RegularExpressions.Regex]::IsMatch($itemName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
            $errorMessage = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $itemName
            @{ "result" = $false; "message" = $errorMessage }
            return;
        }
        @{ "result" = $true; "message" = $null }
    }

    end {
        Write-Verbose "Cmdlet Test-ItemName - End"
    }
}
