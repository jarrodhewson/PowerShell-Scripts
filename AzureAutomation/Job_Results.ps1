$O365Cred = Get-AutomationPSCredential -Name '365Admin'
$SMTPCreds = Get-AutomationPSCredential -Name 'JarrodTest'

Login-AzureRmAccount –Credential $O365Cred

$PSEmailServer = "smtp.office365.com" 
$SMTPSender = "jarrod.test@lexel.co.nz"

$Runbooks = @()
$Runbooks += "License_EMS"
$Runbooks += "License_Office365"
$Runbooks += "License_Office365_E5"
$Runbooks += "License_PowerBIPro"
$Runbooks += "Unlicense_Office365_E3"
$Runbooks += "Unlicense_Office365_E5"

$Output = ""

foreach($runbook in $Runbooks){
    $YesterdayJobs = (Get-AzureRmAutomationJob -ResourceGroupName AutomationResourceGroup -AutomationAccountName LexelAutomation -RunbookName $runbook)|where starttime -gt (Get-Date).AddDays(-1)
    foreach($job in $YesterdayJobs){
        $Output += "Runbook Name: " + $job.RunbookName + "`n"
        $Output += "Start Time: " + $job.StartTime.DateTime + "`n"
        $Output += "Status: " + $job.Status + "`n" + "`n"
        $Output += "Output" + "`n"
        $Output += "======" + "`n"
        $JobOutput = (Get-AzureRmAutomationJobOutput -ResourceGroupName AutomationResourceGroup -AutomationAccountName LexelAutomation -Id $job.jobid -Stream Output)
        foreach($item in $JobOutput){
            $Output += $item.summary + "`n"
        }    
        $Output += "`n" + "--------------------------------------------------------------------------------" + "`n" + "`n"
    }
}




#Send-MailMessage -To jarrod.hewson@lexel.co.nz -From jarrod.test@lexel.co.nz -Subject "Test" -Body "testing body" -UseSsl -Port 587 -Credential $SMTPCreds
Send-MailMessage -To jarrod.hewson@lexel.co.nz -Subject "Licensing Script Output" -Body $Output -From $SMTPSender -UseSsl -Port 587 -Credential $SMTPCreds
