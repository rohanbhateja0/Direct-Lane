function Test-BrokenLinks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Item
    )

    begin {
        Write-Verbose "Cmdlet Test-BrokenLinks - Begin"
    }

    process {
        Write-Verbose "Cmdlet Test-BrokenLinks - Process"
        [Sitecore.Text.UrlString]$url = [Sitecore.UIUtil]::GetUri("control:BreakingLinks")
        $liststring = [Sitecore.Text.ListString]::new($Item.Paths.Path, '|')
        $url.Append("ignoreclones", "0");
        $url.Append("language", $Item.Language.Name);

        $handle = [Sitecore.Web.UrlHandle]::new()
        $handle["list"] = $liststring.ToString()
        $handle.Add($url)

        $msg = [Spe.Commands.Interactive.Messages.ShowModalDialogPsMessage]::new($url.ToString(), $null, $null, @{list = $liststring })
        [Spe.Commands.Interactive.BaseShellCommand]::PutMessage($msg)
        $msg.GetResult() -eq "yes"
    }

    end {
        Write-Verbose "Cmdlet Test-BrokenLinks - End"
    }
}
