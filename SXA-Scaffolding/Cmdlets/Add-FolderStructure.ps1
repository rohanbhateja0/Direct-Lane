function Add-FolderStructure {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
        [string]$Path,

	    [Parameter(Mandatory=$false, Position=1 )]
        [string]$ItemType = "System/Media/Media folder"
    )

	begin {
		Write-Verbose "Cmdlet Add-FolderStructure - Begin"
	}

	process {
    	$Path = $Path.Replace("master:","")
        $items = $Path.Split('/') | Where-Object{ $_ -ne ""}
    	foreach($folder in $items)
    	{
    	    $temp = $curPath + "/" + $folder
    	    if((Test-Path -Path $temp)){
    	    }else{
    	        New-Item -Path $curPath -Name $folder -ItemType $itemType > $null
    	    }
    	    $curPath = $curPath + "/" + $folder
    	}
    	Get-Item -Path $curPath		
	}

	end {
		Write-Verbose "Cmdlet Add-FolderStructure - End"
	}
}