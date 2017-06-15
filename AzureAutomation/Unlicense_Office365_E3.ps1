$O365Cred = Get-AutomationPSCredential -Name '365Admin'
Connect-MSOLService –Credential $O365Cred

$LicenseGroup = "CloudLicense_Office365E3"
$LicenseName = "Lexel1:ENTERPRISEPACK"
$LicenseOptions = New-MsolLicenseOptions –AccountSkuId $LicenseName -DisabledPlans $null

$LicenseUsers = @()
$currentLicensedUsers = @()
$LicenseExceptions = @()
$LicensedDisabled = @()
$UnlicenseExceptions = @()

$LicenseExceptions += "_tmpl_Sales@lexel.co.nz"
$LicenseExceptions += "packing@lexel.co.nz"
$LicenseExceptions += "PSTDashboard@lexel.co.nz"

$UnlicenseExceptions += "365admin@Lexel1.onmicrosoft.com"

# Display Current Licensing details
$LicenseSKU = Get-MsolAccountSku | where AccountSkuId -eq $LicenseName
$LicenseActive = $LicenseSKU.ActiveUnits
$LicenseWarning = $LicenseSKU.WarningUnits
$LicenseUsed = $LicenseSKU.ConsumedUnits

"Current Licensing: $LicenseActive Active, $LicenseUsed Used, $LicenseWarning Warning"

# Function to retrieve users from nested groups
function Get-NestedMSOLGroupMember {
    [CmdletBinding()] 
    param 
    (
    [Parameter(Mandatory)] 
    [string]$ObjectID 
    )

    ## Find all members  in the group specified 
    $MSOLmembers = Get-MsolGroupMember -GroupObjectId $ObjectID 
    foreach ($MSOLmember in $MSOLmembers){
        ## If any member in  that group is another group just call this function again 
        if ($MSOLmember.GroupMemberType -eq 'group'){
            Get-NestedMSOLGroupMember -ObjectID $MSOLmember.ObjectID
        } elseif ($MSOLmember.GroupMemberType -eq 'user'){
            ## otherwise, just  output the non-group object (probably a user account)
            $Global:LicenseUsers += (Get-MsolUser -ObjectId $MSOLmember.ObjectId).userprincipalname
        }
    }
}

# Run function and populate global variable
Get-NestedMSOLGroupMember -ObjectID (Get-MsolGroup -All | where DisplayName -eq $LicenseGroup).ObjectId
$LicenseUsers = $LicenseUsers | Select -Unique

# Remove any exceptions
$LicenseUsers = $LicenseUsers | ?{$LicenseExceptions -notcontains $_}

# Removed Disabled but Licensed Users
$LicensedDisabled = (Get-MsolUser -EnabledFilter DisabledOnly |where IsLicensed -eq $true).UserPrincipalName
$LicenseUsers = $LicenseUsers | ?{$LicensedDisabled -notcontains $_}

# Count users
$UserCount = $LicenseUsers.count
"Users requiring licenes: $UserCount"

if(($UserCount -eq 0) -or ($UserCount -eq $null)){
    "User count null or zero - exiting script"
    break
}

<#
# Check if each user is licensed and apply new license
foreach($UserUPN in $LicenseUsers){
    $isLicenseApplied=$false
    $onlineUser = Get-MsolUser -UserPrincipalName $UserUPN
    #Check if licensed
    if($onlineUser.IsLicensed -eq $false){
        # Check Usage location first
        if($onlineUser.UsageLocation -eq $null){
            Set-MsolUser -UserPrincipalName $UserUPN -UsageLocation NZ
        }
    }
    $licenses = $onlineUser.Licenses
    foreach($license in $licenses){
        if($license.AccountSkuId -eq $LicenseName){
            $IsLicenseApplied=$true
        }
    }
    if(!$isLicenseApplied){
         #Set-MsolUserLicense -UserPrincipalName $UserUPN -AddLicense $LicenseName -LicenseOptions $LicenseOptions
         "TEST - Applying $LicenseName License - $UserUPN"
    }
}
#>

# Retrieve all licensed users
$AllLicensedUsers = Get-MsolUser -All | where isLicensed -eq $true

# Find licensed users with specific license SKU
foreach($LicensedUser in $AllLicensedUsers){
    if($LicensedUser.Licenses.AccountSkuId -contains $LicenseName){
        $currentLicensedUsers += $LicensedUser.UserPrincipalName
    }
}

# Get Difference in two arrays between current licensed users (online) and expected licensed users (group)
$LicensesToRemove = $currentLicensedUsers | ?{$LicenseUsers -notcontains $_}

# Remove any Unlicense exceptions
$LicensesToRemove = $LicensesToRemove | ?{$UnlicenseExceptions -notcontains $_}

# Count users
$UserCountUnLicense = $LicensesToRemove.count
"Users requiring license removal: $UserCountUnLicense"

# Remove licenses from users not in group
foreach($UserUPN in $LicensesToRemove){
    #Set-MsolUserLicense -UserPrincipalName $UserUPN -RemoveLicenses $LicenseName 
    "TEST - Removing $LicenseName License - $UserUPN"
}
