function Get-FieldSourceMapping {
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "Cmdlet Get-FieldSourceMapping - Begin"        
    }

    process {
        Write-Verbose "Cmdlet Get-FieldSourceMapping - Process"
        $mapping = @{}
        $mapping.Add("General Link", "query:`$site")
        $mapping.Add("Image", "query:`$siteMedia")
        $mapping.Add("Droplink", "query:`$site")
        $mapping.Add("Droptree", "query:`$site")
        $mapping.Add("File", "query:`$siteMedia")
        $mapping.Add("Internal Link", "query:`$home")
        $mapping
    }
    end {
        Write-Verbose "Cmdlet Get-FieldSourceMapping - End"
    }
}