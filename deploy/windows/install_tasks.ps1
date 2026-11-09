# Registers the two scheduled tasks (run as SYSTEM). Run once from an elevated PowerShell.
param([int]$Port = 8015)
$ps = "powershell.exe"
$repeat15 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 15)
$repeat5 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 5)
$boot = New-ScheduledTaskTrigger -AtStartup
$sys = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -MultipleInstances IgnoreNew

Register-ScheduledTask -Force -TaskName "15MW Tick" -Principal $sys -Settings $settings -Trigger $repeat15 `
    -Action (New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\tick.ps1`"")

Register-ScheduledTask -Force -TaskName "15MW Web" -Principal $sys -Settings $settings -Trigger @($boot, $repeat5) `
    -Action (New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\serve.ps1`" -Port $Port")
