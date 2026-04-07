# Helper function to add timestamp to Write-Host messages and log to SPE log
function Write-HostWithTimestamp {
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Message = "",
        [Parameter(Mandatory=$false)]
        [System.ConsoleColor]$ForegroundColor
    )
    $timestamp = [DateTime]::Now.ToString("HH:mm:ss.fff")
    $logMessage = "[$timestamp] $Message"
    
    # Write to console
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        Microsoft.PowerShell.Utility\Write-Host $logMessage -ForegroundColor $ForegroundColor
    }
    else {
        Microsoft.PowerShell.Utility\Write-Host $logMessage
    }
    
    # Write to SPE log file
    try {
        # Determine log level based on message content or use Info as default
        $logLevel = "Info"
        if ($Message -match "Error|Failed|Exception") {
            $logLevel = "Error"
        }
        elseif ($Message -match "Warning|Warn") {
            $logLevel = "Warning"
        }
        
        Write-Log -Log $logLevel -Message $logMessage -ErrorAction SilentlyContinue
    }
    catch {
        # Silently fail if logging fails
    }
}

