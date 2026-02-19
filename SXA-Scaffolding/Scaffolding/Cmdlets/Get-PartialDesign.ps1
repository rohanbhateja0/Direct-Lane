function Get-PartialDesign {
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$true, ValueFromPipeline = $true, Position=0 )]
		[Item]$Root
        )

	begin {
	    Import-Function Test-ItemIsPartialDesign
		Write-Verbose "Cmdlet Get-PartialDesign - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-PartialDesign - Process"   
		Get-ChildItem -Path $Root.Paths.Path -Recurse -Language $Root.Language | ? { (Test-ItemIsPartialDesign $_ ) -eq $true } | Select-Object -First 1
	} 

	end {
		Write-Verbose "Cmdlet Get-PartialDesign - End"
	}
}