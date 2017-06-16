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
        # Returning the Time Object wasn't giving it in NZST
        $UTCRunbookTime = $job.StartTime.DateTime.ToUniversalTime()
        $NZSTOffset = ([TimeZoneInfo]::FindSystemTimeZoneById("New Zealand Standard Time")).BaseUtcOffset
        $NZSTRunbookTime = $UTCRunbookTime + $NZSTOffset

        $Output += "Runbook Name: " + $job.RunbookName + "`n </br>" 
        $Output += "Start Time: " + $NZSTRunbookTime + " (NZST)`n </br>"
        $Output += "Status: " + $job.Status + "`n </br>" + "`n </br>"
        $Output += "Output" + "`n </br>"
        $Output += "======" + "`n </br>"
        $JobOutput = (Get-AzureRmAutomationJobOutput -ResourceGroupName AutomationResourceGroup -AutomationAccountName LexelAutomation -Id $job.jobid -Stream Output)
        foreach($item in $JobOutput){
            $Output += $item.summary + "`n </br>"
        }    
        $Output += "`n </br>" + "--------------------------------------------------------------------------------" + "`n </br>" + "`n </br>"
    }
}

Send-MailMessage -To jarrod.hewson@lexel.co.nz -Subject "Licensing Script Output" -BodyAsHTML $Output -From $SMTPSender -UseSsl -Port 587 -Credential $SMTPCreds
