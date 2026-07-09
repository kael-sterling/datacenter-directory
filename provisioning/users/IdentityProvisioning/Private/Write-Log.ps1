function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('Debug', 'Verbose', 'Info', 'Warning', 'Error')]
        [string]$Level,

        [Parameter(Mandatory, Position = 1)]
        [AllowEmptyString()]
        [AllowNull()]
        [object]$Message,

        [Parameter(Position = 2)]
        [string]$Context
    )

    # Determine debug/verbose state
    $debugEnabled = (
        $PSBoundParameters.ContainsKey('Debug') -or
        $DebugPreference -eq 'Continue'
    )

    $verboseEnabled = (
        $PSBoundParameters.ContainsKey('Verbose') -or
        $VerbosePreference -eq 'Continue' -or
        $debugEnabled
    )

    # Timestamp
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    # Caller function name
    $caller = (Get-PSCallStack)[1].FunctionName
    # $callerName = $caller?.Value?.MyCommand?.Name
    if (-not $caller) { $caller = "<no-caller>" }

    # Runspace/thread ID
    # $runspaceId = [System.Threading.Thread]::CurrentThread.ManagedThreadId

    # Prefix selection
    if ($debugEnabled) {
        # Script name
        # $scriptName = Split-Path $MyInvocation.ScriptName -Leaf
        # $prefix = "[$timestamp][$scriptName][$caller]"#[T:$runspaceId]"
        $prefix = "[$timestamp][$caller]"#[T:$runspaceId]"
    }
    else {
        $prefix = "[$timestamp][$caller]"
    }

    if ($Context) {
        $prefix += "[$Context]"
    }

    # Normalize message into a safe string
    if ($null -eq $Message) {
        $Message = "<null>"
    }
    elseif ($Message -is [System.Exception]) {
        $Message = $Message.ToString()
    }
    elseif ($Message -isnot [string]) {
        try {
            $Message = $Message | ConvertTo-Json -Depth 10 -ErrorAction Stop
        }
        catch {
            $Message = $Message.ToString()
        }
    }





    # Emit log at correct level
    switch ($Level) {
        'Debug' {
            if ($debugEnabled) {
                Write-Debug "$prefix $Message"
            }
        }
        'Verbose' {
            if ($verboseEnabled) {
                Write-Verbose "$prefix $Message"
            }
        }
        'Info' { Write-Host    "$prefix $Message" }
        'Warning' { Write-Warning "$prefix $Message" }
        'Error' { Write-Error   "$prefix $Message" }
    }
}
