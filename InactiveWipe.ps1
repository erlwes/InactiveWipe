<#PSScriptInfo

    .VERSION 1.0.5
    .GUID d885e931-8339-4f02-9fd2-9d5d9c32a8cc
    .AUTHOR Erlend Westervik
    .COMPANYNAME
    .COPYRIGHT
    .TAGS Entra, Azure, PowerShell, GraphAPI, Automation, User Management, EntraID, Guest, Guests, User, Users
    .LICENSEURI
    .PROJECTURI https://github.com/erlwes/InactiveWipe
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES 
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES
        Version: 1.0.0 - Original published version
        Version: 1.0.1 - Fixed so that errormessage for Graph-requests displayed correctly
        Version: 1.0.2 - Added script-metadata and PSScriptInfo, for publishing to PSGallery      
        Version: 1.0.5 - Made the script usable in PowerShell 5.1. Some encoding was unsupported, and also errormessage was not supported on parameter validatescript
#>

<#
.SYNOPSIS
    A graphical interface script to help stay in control of guest access in Entra ID. The tool helps identify disabled, inactive and never-used guest users.

.DESCRIPTION
    The script is designed to authenticate to Microsoft Graph API using the provided tenant ID, application ID, and secret. It retrieves all user accounts and analyzes their activity, categorizing them based on the last login date, disabled status, and invitation acceptance.

    The script requires the 'User Read All' and 'AuditLog.Read.All' Microsoft Graph permissions.
    Guide here: https://github.com/erlwes/InactiveWipe/blob/main/AppRegistration.md

.PARAMETER TenantId
    Specifies the Tenant ID for authentication against Microsoft Graph API. Must be a valid GUID.

.PARAMETER AppId
    Specifies the Application ID for authentication against Microsoft Graph API. Must be a valid GUID.

.PARAMETER AppSecret
    Specifies the Application Secret for authentication against Microsoft Graph API.

.PARAMETER ThresholdDaysAgo
    Optional parameter to define the inactivity threshold in days. Defaults to 180 days.

.PARAMETER memberMode
Optional switch parameter to toggle between processing guest or member accounts. If not specified, the script defaults to processing guest accounts. This parameter is experimental.

.EXAMPLE
    .\InactiveWipe.ps1 -TenantId <your-tenant-id> -AppId <your-app-id> -AppSecret <your-app-secret> -ThresholdDaysAgo 90
    
    This example retrieves all guest user accounts that have been inactive for the last 90 days and outputs the analysis results.
#>

Param (
    [Parameter(Mandatory = $true)][ValidateScript({$_  -match "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$"})]
    [string]$TenantId,

    [Parameter(Mandatory = $true)][ValidateScript({$_  -match "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$"})]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$AppSecret,

    [Parameter(Mandatory = $false)]
    [int]$ThresholdDaysAgo = 180,

    [Parameter(Mandatory = $false)]
    [switch]$MemberMode #EXPERIMENTAL!

)
'';''
$banner = @'
██╗███╗░░██╗░█████╗░░█████╗░████████╗██╗██╗░░░██╗███████╗░██╗░░░░░░░██╗██╗██████╗░███████╗
██║████╗░██║██╔══██╗██╔══██╗╚══██╔══╝██║██║░░░██║██╔════╝░██║░░██╗░░██║██║██╔══██╗██╔════╝
██║██╔██╗██║███████║██║░░╚═╝░░░██║░░░██║╚██╗░██╔╝█████╗░░░╚██╗████╗██╔╝██║██████╔╝█████╗░░
██║██║╚████║██╔══██║██║░░██╗░░░██║░░░██║░╚████╔╝░██╔══╝░░░░████╔═████║░██║██╔═══╝░██╔══╝░░
██║██║░╚███║██║░░██║╚█████╔╝░░░██║░░░██║░░╚██╔╝░░███████╗░░╚██╔╝░╚██╔╝░██║██║░░░░░███████╗
╚═╝╚═╝░░╚══╝╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═╝░░░╚═╝░░░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░░░░╚══════╝
'@
if (($Host.Version.Major) -gt 5) {    
    Write-Host $banner
}

if($memberMode) {
    $UserType = 'Member'    
    $UserPlural = 'members'
}
else {
    $UserType = 'Guest'
    $UserPlural = 'guests'
}
$Selection = ''

#Region Functions
Function Write-Log {
    param([string]$File, [ValidateSet(0, 1, 2, 3, 4)][int]$Level, [Parameter(Mandatory=$true)][string]$Message, [switch]$Silent)
    $Message = $Message.Replace("`r",'').Replace("`n",' ')
    switch ($Level) {
        0 { $Status = 'Info'    ;$FGColor = 'White'   }
        1 { $Status = 'Success' ;$FGColor = 'Green'   }
        2 { $Status = 'Warning' ;$FGColor = 'Yellow'  }
        3 { $Status = 'Error'   ;$FGColor = 'Red'     }
        4 { $Status = 'Console' ;$FGColor = 'Gray'    }
        Default { $Status = ''  ;$FGColor = 'Black'   }
    }
    if (-not $Silent) {
        Write-Host "$((Get-Date).ToString()) " -ForegroundColor 'DarkGray' -NoNewline
        Write-Host "$Status" -ForegroundColor $FGColor -NoNewline

        if ($level -eq 4) {
            Write-Host ("`t " + $Message) -ForegroundColor 'Cyan'
        }
        else {
            Write-Host ("`t " + $Message) -ForegroundColor 'White'
        }
    }
    if ($Level -eq 3) {
        $LogErrors += $Message
    }
    if ($File) {
        try {
            if ($Clear) {
                Out-File -FilePath "$File" -Force
            }
            (Get-Date).ToString() + "`t$($Script:ScriptUser)@$env:COMPUTERNAME`t$Status`t$Message" | Out-File -Append -FilePath "$File" -ErrorAction Stop
        } catch {
            Write-Host "Failed to write log! ($($_.Exception.Message))" -ForegroundColor Red
        }
    }
}

Function Update-Gauges {
    [int]$Script:disabledPercentage = ($DisabledCount / $totalCount) * 100
    [int]$Script:neverSignedInPercentage = ($NeverSignedInCount / $totalCount) * 100
    [int]$Script:inactivePercentage = ($InactiveCount / $totalCount) * 100

    $Script:PossibleToRemoveCount = ($DisabledCount + $NeverSignedInCount + $InactiveCount)
    [int]$Script:ResultsPercentage = ($PossibleToRemoveCount / $totalCount) * 100

    $ResultsLocationY = ($ResultsLabel.Location.Y + 31) + (100 - $ResultsPercentage)
    $ResultsGauge.Location = New-Object Drawing.Point ($ResultsLabel.Location.X + 6),$ResultsLocationY
    $ResultsGauge.Width = 30
    $ResultsGauge.Height = $Script:ResultsPercentage

    if ($ResultsPercentage -le 5) {$ResultsGauge.BackColor = $gaugelevel1}
    elseif ($ResultsPercentage -le 10) {$ResultsGauge.BackColor = $gaugelevel2}
    elseif ($ResultsPercentage -le 15) {$ResultsGauge.BackColor = $gaugelevel3}
    elseif ($ResultsPercentage -gt 15) {$ResultsGauge.BackColor = $gaugelevel4}
    
}

Function Update-Text {
    $disabledInfoTextBox.Clear()
    $disabledInfoTextBox.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $disabledInfoTextBox.AppendText("$([int]$Script:disabledPercentage)%`n")
    $disabledInfoTextBox.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))
    $disabledInfoTextBox.AppendText("$($disabledCount) out of $($totalCount)`n$UserPlural are disabled.")

    $neverSignedInInfoTextBox.Clear()
    $neverSignedInInfoTextBox.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $neverSignedInInfoTextBox.AppendText("$([int]$Script:neverSignedInPercentage)%`n")
    $neverSignedInInfoTextBox.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))
    $neverSignedInInfoTextBox.AppendText("$($neverSignedInCount) out of $totalCount`n$UserPlural never signed in or did not accept invitation.")

    $inactiveInfoTextBox.Clear()
    $inactiveInfoTextBox.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $inactiveInfoTextBox.AppendText("$([int]$Script:inactivePercentage)%`n")
    $inactiveInfoTextBox.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))
    $inactiveInfoTextBox.AppendText("$($inactiveCount) out of $totalCount`n$UserPlural has no logins for the last $ThresholdDaysAgo days.")

    $ResultText.Clear()
    $ResultText.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $ResultText.AppendText("$([int]$Script:ResultsPercentage)%`n")
    $ResultText.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))    
    $ResultText.AppendText("$Script:PossibleToRemoveCount out $TotalCount `n$UserPlural can potentially `nbe wiped.")

    $InsightsInfoTextBox.Clear()
    $InsightsInfoTextBox.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $InsightsInfoTextBox.AppendText("Insights ")
    New-Object System.Drawing.Font("Wingdings", '20')
    $InsightsInfoTextBox.SelectionFont = (New-Object Drawing.Font("Wingdings", '20'))
    $InsightsInfoTextBox.SelectionColor = $Yellow
    $InsightsInfoTextBox.AppendText("R")
    $InsightsInfoTextBox.SelectionColor = $LabelColor

    $InsightsInfoTextBox.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))
    if (!$memberMode) {
        $InsightsInfoTextBox.AppendText("`n`n$($totalCount) out of $(($result.value).count) users are $UserPlural (~$((($($TotalCount / ($result.value).count)) * 100) -replace "\..+$")%)")
        $InsightsInfoTextBox.AppendText("`n`nGuests are distributed across $(($EmailDomains | Select-Object -Unique).count) unique email domains")
    }
}
#Endregion Functions

'';Write-Log -Level 4 -Message  'Start'

#Region GraphAuth
$url = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$resource = 'https://graph.microsoft.com/'
$restbody = @{
    grant_type    = 'client_credentials'
    client_id     = $appId
    client_secret = $AppSecret
    resource      = $resource
}
try {
    $token = Invoke-RestMethod -Method POST -Uri $url -Body $restbody -ErrorAction Stop
    Write-Log -Level 1 -Message 'Invoke-RestMethod: Auth'
    Remove-Variable -Name tenantId, appId, appSecret, restbody -ErrorAction SilentlyContinue
}
catch {
    Write-Log -Level 3 -Message "Invoke-RestMethod - Auth error: URL: '$url'"
    Write-Log -Level 3 -Message "Invoke-RestMethod - Auth error: Exception: $($_.Exception.Message)"
    Write-Log -Level 2 -Message "Closing script - can not continue without auth"
    Throw
}
#endregion GraphAuth

#Region GraphQuery
$AllResults = @()
$header = @{
    'Authorization' = "$($Token.token_type) $($Token.access_token)"
    'Content-type'  = 'application/json'
}
$url = "https://graph.microsoft.com/beta/users?`$top=999&`$select=accountEnabled,createdDateTime,creationType,externalUserState,userType,companyName,displayName,jobTitle,mail,signInActivity,userPrincipalName,AssignedLicenses"

try {
    $Result = Invoke-RestMethod -Method GET -headers $header -Uri $url -ErrorAction Stop
    Write-Log -Level 1 -Message "Invoke-RestMethod: Query '$($url.Substring(0, 55) + '...')'"
    $AllResults += $Result.value
    $NextPage = $Result.'@odata.nextLink'
    
    $i = 2
    While ($null -ne $NextPage) {
        try {
            Clear-Variable AdditionalResults -ErrorAction SilentlyContinue
            $AdditionalResults = Invoke-RestMethod -Method GET -headers $header -Uri $NextPage -ErrorAction Stop
            Write-Log -Level 1 -Message "Invoke-RestMethod: Query, page $i '$($url.Substring(0, 55) + '...')'"
            $AllResults += $AdditionalResults.value
            $NextPage = $AdditionalResults.'@odata.nextLink'
            $i ++
        }
        catch {
            Write-Log -Level 3 -Message "Invoke-RestMethod - Query error: '$url' $($_.Exception.Message)"
        }
    }
    Remove-Variable -Name token -ErrorAction SilentlyContinue
}
catch {    
    Write-Log -Level 3 -Message "Invoke-RestMethod - Query error: URL: '$url'"
    Write-Log -Level 3 -Message "Invoke-RestMethod - Query error: Exception: $($_.Exception.Message)"
    Write-Log -Level 2 -Message "Closing script - can not continue without graph query results"    
    Throw
}
#endregion GraphQuery

# Uncomment to inspect raw results and quit
#$result.value | Out-GridView;break

#Region ProcessGuests
Write-Log -Level 0 -Message  "Process Graph-results - Start"
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$AllUsers = @()
$DisabledGuests = @()
$EnabledGuests = @()
$InactiveUsers = @()
$NeverSignedIn = @()
$NotAcceptedInvitation = @()
$EmailDomains = @()
$ThresholdDaysAgo = [int]$ThresholdDaysAgo

$AllResults | ForEach-Object {
    $user = $_
    if ($user.UserType -eq $UserType) {
        
        Clear-Variable DaysSinceLastLogin, DaysSinceLastNonIntLogin, DateLastLogin, UserObj -ErrorAction SilentlyContinue
        
        # Calculate days since last login
        if ($user.signInActivity.lastSignInDateTime) {
            $DaysSinceLastLogin = [int]((Get-Date) - [datetime](Get-Date ($user.signInActivity.lastSignInDateTime) -ErrorAction SilentlyContinue)).TotalDays
        }
        else {
            $DaysSinceLastLogin = $null
        }

        # Calculate days since last non-int login
        if ($user.signInActivity.lastNonInteractiveSignInDateTime -eq $null) {
            $DaysSinceLastNonIntLogin = $null
        }
        else {
            $DaysSinceLastNonIntLogin = [int]((Get-Date) - [datetime](Get-Date ($user.signInActivity.lastNonInteractiveSignInDateTime))).TotalDays
        }
        
        # Change date-format on last login date
        if ($user.signInActivity.lastSignInDateTime) {
            $DateLastLogin = [datetime](Get-Date ($user.signInActivity.lastSignInDateTime))
        }
        else {
            $DateLastLogin = $null
        }

        $UserObj = [pscustomobject]@{
            UserType                  = $user.UserType
            accountEnabled            = $user.accountEnabled
            creationType              = $user.creationType
            externalUserState         = $user.externalUserState
            createdDateTime           = [datetime](Get-Date ($user.createdDateTime))
            companyName               = $user.companyName
            displayName               = $user.displayName
            jobTitle                  = $user.jobTitle
            userPrincipalName         = ($user.userPrincipalName).ToLower()
            AssignedLicenses          = $user.AssignedLicenses
            mail                      = ($user.mail).ToLower()
            mailDomain                = ($user.mail).ToLower() -replace '^.+@'
            DateLastLogin             = $DateLastLogin
            DaysSinceLastLogin        = $DaysSinceLastLogin
            DateLastNonIntLogin       = if ($DaysSinceLastNonIntLogin -ne $null) { [datetime](Get-Date ($user.signInActivity.lastNonInteractiveSignInDateTime)) } else { $null }
            DaysSinceLastNonIntLogin  = $DaysSinceLastNonIntLogin
        }

        $EmailDomains += $UserObj.mailDomain

        $AllUsers += $UserObj        
        if ($user.accountEnabled -eq $false) {
            $DisabledGuests += $UserObj
        }
        else {
            $EnabledGuests += $UserObj
            if ($DaysSinceLastLogin -ge $ThresholdDaysAgo -and ($DaysSinceLastNonIntLogin -eq $null -or $DaysSinceLastNonIntLogin -ge $ThresholdDaysAgo)) {
                $InactiveUsers += $UserObj
            }
            if ($user.signInActivity.lastSignInDateTime -eq $null -and $user.signInActivity.lastNonInteractiveSignInDateTime -eq $null) {
                $NeverSignedIn += $UserObj
                if ($user.externalUserState -eq 'PendingAcceptance') {
                    $NotAcceptedInvitation += $UserObj
                }
            }
        }
    }    
}
$timer.Stop()
Write-Log -Level 0 -Message  "Process Graph-results - Done in $($timer.Elapsed.TotalSeconds) seconds"
Write-Log -Level 0 -Message  "[$($AllResults.count)]`tTotal: Users found"
Write-Log -Level 0 -Message  "[$($AllUsers.count)]`t  Guests: all guests"
Write-Log -Level 0 -Message  "[$($DisabledGuests.count)]`t    Disabled: Guest users that are disabled"
Write-Log -Level 0 -Message  "[$($EnabledGuests.count)]`t    Enabled: Guest users that are enabled"
Write-Log -Level 0 -Message  "[$($InactiveUsers.count)]`t    Inactive: Guests that have not logged in last $ThresholdDaysAgo+ days"
Write-Log -Level 0 -Message  "[$($NeverSignedIn.count)]`t    No logins: Guests that have not yet logged in"
Write-Log -Level 0 -Message  "[$($NotAcceptedInvitation.count)]`t    Invited: Guests that have not accepted invitation to Entra ID"

$TotalCount = $AllUsers.Count
$DisabledCount = $DisabledGuests.Count
$NeverSignedInCount = $NeverSignedIn.Count
$InactiveCount = $InactiveUsers.Count
#Endregion ProcessGuests

#region style
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[System.Windows.Forms.Application]::EnableVisualStyles()

$BackgroundColor = [System.Drawing.Color]::FromArgb(255,220,220,220)
$GaugeLabel = [System.Drawing.Color]::FromArgb(255,200,200,200)
$WrapperBackgroundColor = [System.Drawing.Color]::FromArgb(255,245,245,245)

$LabelFontH2 = New-Object System.Drawing.Font('Calibri Light', '12')
$LabelFontH1 = New-Object System.Drawing.Font('Calibri Light', '14', [System.Drawing.FontStyle]::Bold)
$ListIconFont = New-Object System.Drawing.Font("Wingdings", '20') #N For eye 2 for list

$LabelColor = [System.Drawing.Color]::FromArgb(255,50,50,50)
$LabelColorEnter = [System.Drawing.Color]::FromArgb(255,252,133,77)
$Yellow = [System.Drawing.Color]::FromArgb(255,215,200,0)

$gaugelevel1 = [System.Drawing.Color]::FromArgb(255,107,201,104) # green
$gaugelevel2 = [System.Drawing.Color]::FromArgb(255,254,209,54) # yellow
$gaugelevel3 = [System.Drawing.Color]::FromArgb(255,252,133,77) # orange
$gaugelevel4 = [System.Drawing.Color]::FromArgb(255,253,87,99) # red

$Spacing = 15
#endregion style

#region Main form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "InactiveWipe [$UserType mode]"
$Form.SizeGripStyle = 'Hide'
$Form.FormBorderStyle = 'Fixed3D'
$Form.ClientSize = '500,300'
$Form.Font = New-Object System.Drawing.Font("Calibri",10)
$Form.BackColor = $BackgroundColor
$Form.MaximizeBox = $False
$Form.KeyPreview = $True
$Form.Add_KeyDown({
    if ($PSItem.KeyCode -eq "Escape") {
        $Form.Close()
        $_.SuppressKeyPress = $true
    }
})
#endregion Main form

#region Disabled
$disabledLabel = New-Object System.Windows.Forms.Label
$disabledLabel.Location = New-Object Drawing.Point $Spacing,$Spacing
$disabledLabel.Text = 'Disabled'
$disabledLabel.Font = $LabelFontH2
$disabledLabel.BackColor = $WrapperBackgroundColor
$disabledLabel.ForeColor = $LabelColor
$disabledLabel.ClientSize = '120,20'

$disabledResultListLabel = New-Object System.Windows.Forms.Label
$disabledResultListLabel.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 117),($disabledLabel.Location.Y - 2)
$disabledResultListLabel.Text = '2' #Using the Wingdings font, the number 2 represents a list-icon
$disabledResultListLabel.Font = $ListIconFont
$disabledResultListLabel.BackColor = $WrapperBackgroundColor
$disabledResultListLabel.ForeColor = $LabelColor
$disabledResultListLabel.ClientSize = '25,25'
$disabledResultListLabel.Add_MouseEnter({
    $disabledResultListLabel.ForeColor = $LabelColorEnter
})
$disabledResultListLabel.Add_MouseLeave({
    $disabledResultListLabel.ForeColor = $LabelColor
})
$disabledResultListLabel.add_click({
    Clear-Variable Selection -ErrorAction SilentlyContinue
    $Selection = $DisabledGuests | Out-GridView -Title "Disabled $($UserType.ToLower()) users [$($DisabledGuests.count)]" -OutputMode Multiple
    $Selection.userPrincipalName | Set-Clipboard
})

$disabledInfoTextBox = New-Object System.Windows.Forms.RichTextBox
$disabledInfoTextBox.Location = New-Object Drawing.Point ($disabledLabel.Location.X),($disabledLabel.Location.Y + 30)
$disabledInfoTextBox.BackColor = $WrapperBackgroundColor
$disabledInfoTextBox.ClientSize = "140,70"
$disabledInfoTextBox.ReadOnly = $true
$disabledInfoTextBox.BorderStyle = 0

$disabledBackground = New-Object System.Windows.Forms.Label
$disabledBackground.Location = New-Object Drawing.Point ($disabledLabel.Location.X - 5),($disabledLabel.Location.Y - 5)
$disabledBackground.ClientSize = '150,115'
$disabledBackground.BackColor = $WrapperBackgroundColor

$Form.Controls.Add($disabledLabel)
$Form.Controls.Add($disabledResultListLabel)
$Form.Controls.Add($disabledInfoTextBox)
$Form.Controls.Add($disabledGauge)
$Form.Controls.Add($disabledBGGauge)
$Form.Controls.Add($disabledBorderGauge)
$Form.Controls.Add($disabledBackground)
#endregion Disabled

#region NeverSignedIn
$neverSignedInLabel = New-Object System.Windows.Forms.Label
$neverSignedInLabel.Location = New-Object Drawing.Point ($disabledBackground.Width + ($Spacing * 2)),$Spacing
$neverSignedInLabel.Text = 'Never signed in'
$neverSignedInLabel.Font = $LabelFontH2
$neverSignedInLabel.BackColor = $WrapperBackgroundColor
$neverSignedInLabel.ForeColor = $LabelColor
$neverSignedInLabel.ClientSize = '120,20'

$neverSignedInResultListLabel = New-Object System.Windows.Forms.Label
$neverSignedInResultListLabel.Location = New-Object Drawing.Point ($neverSignedInLabel.Location.X + 117),($neverSignedInLabel.Location.Y -2)
$neverSignedInResultListLabel.Text = '2' #Using the Wingdings font, the number 2 represents a list-icon
$neverSignedInResultListLabel.Font = $ListIconFont
$neverSignedInResultListLabel.BackColor = $WrapperBackgroundColor
$neverSignedInResultListLabel.ForeColor = $LabelColor
$neverSignedInResultListLabel.ClientSize = '25,25'
$neverSignedInResultListLabel.Add_MouseEnter({
    $neverSignedInResultListLabel.ForeColor = $LabelColorEnter
})
$neverSignedInResultListLabel.Add_MouseLeave({
    $neverSignedInResultListLabel.ForeColor = $LabelColor
})
$neverSignedInResultListLabel.add_click({
    Clear-Variable Selection -ErrorAction SilentlyContinue
    $Selection = $NeverSignedIn | Out-GridView -Title "Never logged in $($UserType.ToLower()) users [$($NeverSignedIn.count)]" -OutputMode Multiple
    $Selection.userPrincipalName | Set-Clipboard
})

$neverSignedInInfoTextBox = New-Object System.Windows.Forms.RichTextBox
$neverSignedInInfoTextBox.Location = New-Object Drawing.Point ($neverSignedInLabel.Location.X),($neverSignedInLabel.Location.Y + 30)
$neverSignedInInfoTextBox.BackColor = $WrapperBackgroundColor
$neverSignedInInfoTextBox.ClientSize = "140,75"
$neverSignedInInfoTextBox.ReadOnly = $true
$neverSignedInInfoTextBox.BorderStyle = 0

$neverSignedInBackground = New-Object System.Windows.Forms.Label
$neverSignedInBackground.Location = New-Object Drawing.Point ($neverSignedInLabel.Location.X - 5),($neverSignedInLabel.Location.Y - 5)
$neverSignedInBackground.ClientSize = '150,115'
$neverSignedInBackground.BackColor = $WrapperBackgroundColor

$Form.Controls.Add($neverSignedInLabel)
$Form.Controls.Add($neverSignedInResultListLabel)
$Form.Controls.Add($neverSignedInInfoTextBox)
$Form.Controls.Add($neverSignedInGauge)
$Form.Controls.Add($neverSignedInBGGauge)
$Form.Controls.Add($neverSignedInBorderGauge)
$Form.Controls.Add($neverSignedInBackground)
#endregion NeverSignedIn

#region Inactive
$inactiveLabel = New-Object System.Windows.Forms.Label
$inactiveLabel.Location = New-Object Drawing.Point ($disabledBackground.Width + $neverSignedInBackground.Width  + ($Spacing * 3)),$Spacing
$inactiveLabel.Text = 'Inactive'
$inactiveLabel.Font = $LabelFontH2
$inactiveLabel.BackColor = $WrapperBackgroundColor
$inactiveLabel.ForeColor = $LabelColor
$inactiveLabel.ClientSize = '120,20'

$inactiveResultListLabel = New-Object System.Windows.Forms.Label
$inactiveResultListLabel.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 117),($inactiveLabel.Location.Y -2)
$inactiveResultListLabel.Text = '2' #Using the Wingdings font, the number 2 represents a list-icon
$inactiveResultListLabel.Font = $ListIconFont
$inactiveResultListLabel.BackColor = $WrapperBackgroundColor
$inactiveResultListLabel.ForeColor = $LabelColor
$inactiveResultListLabel.ClientSize = '25,25'
$inactiveResultListLabel.Add_MouseEnter({
    $inactiveResultListLabel.ForeColor = $LabelColorEnter
})
$inactiveResultListLabel.Add_MouseLeave({
    $inactiveResultListLabel.ForeColor = $LabelColor
})
$inactiveResultListLabel.add_click({
    Clear-Variable Selection -ErrorAction SilentlyContinue
    $Selection = $InactiveUsers | Out-GridView -Title "Inactive $($UserType.ToLower()) users [$($InactiveUsers.count)]" -OutputMode Multiple
    $Selection.userPrincipalName | Set-Clipboard
})

$inactiveInfoTextBox = New-Object System.Windows.Forms.RichTextBox
$inactiveInfoTextBox.Location = New-Object Drawing.Point ($inactiveLabel.Location.X),($inactiveLabel.Location.Y + 30)
$inactiveInfoTextBox.BackColor = $WrapperBackgroundColor
$inactiveInfoTextBox.ClientSize = "140,70"
$inactiveInfoTextBox.ReadOnly = $true
$inactiveInfoTextBox.BorderStyle = 0

$inactiveBackground = New-Object System.Windows.Forms.Label
$inactiveBackground.Location = New-Object Drawing.Point ($inactiveLabel.Location.X - 5),($inactiveLabel.Location.Y - 5)
$inactiveBackground.ClientSize = '150,115'
$inactiveBackground.BackColor = $WrapperBackgroundColor

$Form.Controls.Add($inactiveLabel)
$Form.Controls.Add($inactiveResultListLabel)
$Form.Controls.Add($inactiveInfoTextBox)
$Form.Controls.Add($inactiveGauge)
$Form.Controls.Add($inactiveBGGauge)
$Form.Controls.Add($inactiveBorderGauge)
$Form.Controls.Add($inactiveBackground)
#endregion Inactive

#Region Total
$ResultsLabel = New-Object System.Windows.Forms.Label
$ResultsLabel.Location = New-Object Drawing.Point $Spacing, ($disabledBackground.Height + ($Spacing * 2))
$ResultsLabel.Text = 'Total'
$ResultsLabel.Font = $LabelFontH1
$ResultsLabel.BackColor = $WrapperBackgroundColor
$ResultsLabel.ForeColor = $LabelColor
$ResultsLabel.ClientSize = '120,20'

$ResultText = New-Object System.Windows.Forms.RichTextBox
$ResultText.Location = New-Object Drawing.Point ($ResultsLabel.Location.X + 85),($ResultsLabel.Location.Y + 30)
$ResultText.Text = '' #See Update-Text function
$ResultText.BackColor = $WrapperBackgroundColor
$ResultText.ClientSize = '135,80'
$ResultText.ReadOnly = $true
$ResultText.BorderStyle = 0
$Form.Controls.Add($ResultText)

$ResultsGauge = New-Object System.Windows.Forms.Label
$ResultsGauge.Location = New-Object Drawing.Point ($ResultsLabel.Location.X + 6),($ResultsLabel.Location.Y + 31)
$ResultsGauge.ClientSize = "30,0"
$ResultsGauge.BackColor = [System.Drawing.Color]::FromArgb(255,100,200,255)

$ResultsBGGauge= New-Object System.Windows.Forms.Label
$ResultsBGGauge.Location = New-Object Drawing.Point ($ResultsLabel.Location.X + 6),($ResultsLabel.Location.Y + 31)
$ResultsBGGauge.ClientSize = '30,100'
$ResultsBGGauge.BackColor = $BackgroundColor

$ResultsBorderGauge= New-Object System.Windows.Forms.Label
$ResultsBorderGauge.Location = New-Object Drawing.Point ($ResultsLabel.Location.X + 5),($ResultsLabel.Location.Y + 30)
$ResultsBorderGauge.ClientSize = '32,102'
$ResultsBorderGauge.BackColor = [System.Drawing.Color]::FromArgb(255,50,50,50)

$ResultsBackground = New-Object System.Windows.Forms.Label
$ResultsBackground.Location = New-Object Drawing.Point ($Spacing - 5),($ResultsLabel.Location.Y - 5)
$ResultsBackground.Width = (($Spacing / 2) + $disabledBackground.Width * 1.5)
$ResultsBackground.Height = '150'
$ResultsBackground.BackColor = $WrapperBackgroundColor

$ResultsGaugeMax = New-Object System.Windows.Forms.Label
$ResultsGaugeMax.Location = New-Object Drawing.Point ($ResultsBGGauge.Location.X + 32),($ResultsBGGauge.Location.Y)
$ResultsGaugeMax.Text = '100%'
$ResultsGaugeMax.BackColor = $WrapperBackgroundColor
$ResultsGaugeMax.ForeColor = $GaugeLabel
$ResultsGaugeMax.ClientSize = '40,20'
$Form.Controls.Add($ResultsGaugeMax)

$ResultsGaugeMin = New-Object System.Windows.Forms.Label
$ResultsGaugeMin.Location = New-Object Drawing.Point ($ResultsBGGauge.Location.X + 32),($ResultsBGGauge.Location.Y + $ResultsBorderGauge.Height - 20)
$ResultsGaugeMin.Text = '0%'
$ResultsGaugeMin.BackColor = $WrapperBackgroundColor
$ResultsGaugeMin.ForeColor = $GaugeLabel
$ResultsGaugeMin.ClientSize = '30,20'
$Form.Controls.Add($ResultsGaugeMin)

$Form.Controls.Add($ResultsLabel)
$Form.Controls.Add($ResultsResultListLabel)
$Form.Controls.Add($ResultsInfoTextBox)
$Form.Controls.Add($ResultsGauge)
$Form.Controls.Add($ResultsBGGauge)
$Form.Controls.Add($ResultsBorderGauge)
$Form.Controls.Add($ResultsBackground)
#endregion Total

#Region Insights
$InsightsInfoTextBox = New-Object System.Windows.Forms.RichTextBox
$InsightsInfoTextBox.Location = New-Object Drawing.Point ($ResultsBackground.Width + ($Spacing * 2) + 5), ($disabledBackground.Height + ($Spacing * 2))
$InsightsInfoTextBox.Text = '' #See Update-Text function
$InsightsInfoTextBox.Width = 222
$InsightsInfoTextBox.Height = 130
$InsightsInfoTextBox.ReadOnly = $true
$InsightsInfoTextBox.BorderStyle = 0
$InsightsInfoTextBox.BackColor = $WrapperBackgroundColor
$Form.Controls.Add($InsightsInfoTextBox)

$InsightsBackground = New-Object System.Windows.Forms.Label
$InsightsBackground.Location = New-Object Drawing.Point ($ResultsBackground.Width + ($Spacing * 1.5) + 3), $ResultsBackground.Location.Y
$InsightsBackground.Width = (($Spacing / 2) + $disabledBackground.Width * 1.5)
$InsightsBackground.Height = $ResultsBackground.Height
$InsightsBackground.BackColor = $WrapperBackgroundColor
$Form.Controls.Add($InsightsBackground)
#Endregion Insights

#region show GUI
$Form.Add_Shown( {
    $Form.add_FormClosing({
        Write-Log -File $LogFile -Level 4 -Message "End"
    })
    Update-Gauges
    Update-Text
    $Form.Activate()
} )
$Form.ShowDialog()
#endregion show GUI
