Param (
    [Parameter(Mandatory = $true)][ValidateScript({$_  -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'}, ErrorMessage = 'Please enter a valid tenant id.')]
    [string]$tenantId,

    [Parameter(Mandatory = $true)][ValidateScript({$_  -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'}, ErrorMessage = 'Please enter a valid application id.')]
    [string]$appId,

    [Parameter(Mandatory = $true)]
    [string]$appSecret,

    [Parameter(Mandatory = $false)]
    [int]$ThresholdDaysAgo = 180
)
'';''
'██╗███╗░░██╗░█████╗░░█████╗░████████╗██╗██╗░░░██╗███████╗░██╗░░░░░░░██╗██╗██████╗░███████╗'
'██║████╗░██║██╔══██╗██╔══██╗╚══██╔══╝██║██║░░░██║██╔════╝░██║░░██╗░░██║██║██╔══██╗██╔════╝'
'██║██╔██╗██║███████║██║░░╚═╝░░░██║░░░██║╚██╗░██╔╝█████╗░░░╚██╗████╗██╔╝██║██████╔╝█████╗░░'
'██║██║╚████║██╔══██║██║░░██╗░░░██║░░░██║░╚████╔╝░██╔══╝░░░░████╔═████║░██║██╔═══╝░██╔══╝░░'
'██║██║░╚███║██║░░██║╚█████╔╝░░░██║░░░██║░░╚██╔╝░░███████╗░░╚██╔╝░╚██╔╝░██║██║░░░░░███████╗'
'╚═╝╚═╝░░╚══╝╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═╝░░░╚═╝░░░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░░░░╚══════╝'
''
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
    $disabledLocationY = ($disabledLabel.Location.Y + 31) + (100 - $disabledPercentage)
    $disabledGauge.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 6),$disabledLocationY
    $disabledGauge.ClientSize = "30,$disabledPercentage"
    if ($disabledPercentage -le 5) {$disabledGauge.BackColor = $gaugelevel1}
    elseif ($disabledPercentage -le 10) {$disabledGauge.BackColor = $gaugelevel2}
    elseif ($disabledPercentage -le 15) {$disabledGauge.BackColor = $gaugelevel3}
    elseif ($disabledPercentage -gt 15) {$disabledGauge.BackColor = $gaugelevel4}

    [int]$Script:inactivePercentage = ($InactiveCount / ($EnabledGuests.Count - $neverLoggedInCount)) * 100
    $inactiveLocationY = ($inactiveLabel.Location.Y + 31) + (100 - $inactivePercentage)
    $inactiveGauge.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 6),$inactiveLocationY
    $inactiveGauge.ClientSize = "30,$inactivePercentage"
    if ($inactivePercentage -le 5) {$inactiveGauge.BackColor = $gaugelevel1}
    elseif ($inactivePercentage -le 10) {$inactiveGauge.BackColor = $gaugelevel2}
    elseif ($inactivePercentage -le 15) {$inactiveGauge.BackColor = $gaugelevel3}
    elseif ($inactivePercentage -gt 15) {$inactiveGauge.BackColor = $gaugelevel4}

    [int]$Script:neverLoggedInPercentage = ($NeverLoggedInCount / $EnabledGuests.Count) * 100
    $neverLoggedInLocationY = ($neverLoggedInLabel.Location.Y + 31) + (100 - $neverLoggedInPercentage)
    $neverLoggedInGauge.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 6),$neverLoggedInLocationY
    $neverLoggedInGauge.ClientSize = "30,$neverLoggedInPercentage"
    if ($neverLoggedInPercentage -le 5) {$neverLoggedInGauge.BackColor = $gaugelevel1}
    elseif ($neverLoggedInPercentage -le 10) {$neverLoggedInGauge.BackColor = $gaugelevel2}
    elseif ($neverLoggedInPercentage -le 15) {$neverLoggedInGauge.BackColor = $gaugelevel3}
    elseif ($neverLoggedInPercentage -gt 15) {$neverLoggedInGauge.BackColor = $gaugelevel4}
}

Function Update-Text {
    $disabledInfoTextBox.Clear()
    $disabledInfoTextBox.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $disabledInfoTextBox.AppendText("$([int]$Script:disabledPercentage)%`n")
    $disabledInfoTextBox.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))
    $disabledInfoTextBox.AppendText("$($disabledCount) out of $($totalCount) guest are disabled.")

    $neverLoggedInInfoTextBox.Clear()
    $neverLoggedInInfoTextBox.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $neverLoggedInInfoTextBox.AppendText("$([int]$Script:neverLoggedInPercentage)%`n")
    $neverLoggedInInfoTextBox.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))
    $neverLoggedInInfoTextBox.AppendText("$($neverLoggedInCount) out of $($EnabledGuests.Count) guest never signed in.`n$NotAcceptecInvitationCount did not accept invitation.")

    $inactiveInfoTextBox.Clear()
    $inactiveInfoTextBox.SelectionFont = (New-Object Drawing.Font('Calibri Light', '12', [System.Drawing.FontStyle]::Bold))
    $inactiveInfoTextBox.AppendText("$([int]$Script:inactivePercentage)%`n")
    $inactiveInfoTextBox.SelectionFont = (New-Object Drawing.Font("Calibri", '10'))
    $inactiveInfoTextBox.AppendText("$($inactiveCount) out of $($EnabledGuests.Count - $neverLoggedInCount) has no logins for the last $ThresholdDaysAgo days.")

    $StartText.Text = "$($totalCount) out of $(($result.value).count) users`nare guests (~$((($($TotalCount / ($result.value).count)) * 100) -replace "\..+$")%)"
    $Narrow1Text.Text = "$($EnabledGuests.count) enabled guests are left`tafter leaving out disabled guests"
    $Narrow2Text.Text = "$($EnabledGuests.Count - $NeverLoggedInCount) guests are left, when leaving out those that never signed in"
    
    $PossibleToRemoveCount = ($DisabledGuests.Count + $NeverLoggedInCount + $InactivePass1.count)

    $ResultText.Text = "$PossibleToRemoveCount out $TotalCount could be removed (~$(($($PossibleToRemoveCount / $TotalCount) * 100) -replace "\..+$")%)."
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
    Write-Log -Level 3 -Message "Invoke-RestMethod - Auth error: '$url' $($_.Exeption.Message)"
}
#endregion GraphAuth

#Region GraphQuery
$header = @{
    'Authorization' = "$($Token.token_type) $($Token.access_token)"
    'Content-type'  = 'application/json'
}
$url = "https://graph.microsoft.com/beta/users?`$top=999&`$select=accountEnabled,createdDateTime,creationType,externalUserState,userType,companyName,displayName,jobTitle,mail,signInActivity,userPrincipalName,AssignedLicenses"

try {
    $Result = Invoke-RestMethod -Method GET -headers $header -Uri $url -ErrorAction Stop
    Write-Log -Level 1 -Message "Invoke-RestMethod: Query '$($url.Substring(0, 55) + '...')'"
    Write-Log -Level 0 -Message  "[$(($result.value).count)]`tTotal: Users found"
    Remove-Variable -Name token -ErrorAction SilentlyContinue
}
catch {
    Write-Log -Level 3 -Message "Invoke-RestMethod - Query error: '$url' $($_.Exeption.Message)"
}
#endregion GraphQuery

#Region ProcessGuests
Write-Log -Level 0 -Message  "Process Graph-results - Start"
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$AllGuests = @()
$DisabledGuests = @()
$EnabledGuests = @()
$InactivePass1 = @()
$NeverLoggedIn = @()
$NotAcceptedInvitation = @()
$ThresholdDaysAgo = [int]$ThresholdDaysAgo

$result.value | ForEach-Object {
    $guest = $_
    if ($guest.UserType -eq 'Guest') {
        $AllGuests += $guest        
        if ($guest.accountEnabled -eq $false) {
            $DisabledGuests += $guest
        } else {
            $EnabledGuests += $guest
            if ($guest.signInActivity.lastSignInDateTime) {
                $DaysSinceLastLogin = [int]((Get-Date) - [datetime](Get-Date ($guest.signInActivity.lastSignInDateTime) -ErrorAction SilentlyContinue)).TotalDays
            }
            else {
                $DaysSinceLastLogin = $null
            }
            if ($guest.signInActivity.lastNonInteractiveSignInDateTime -eq $null) {
                $DaysSinceLastNonIntLogin = $null
            }
            else {
                $DaysSinceLastNonIntLogin = [int]((Get-Date) - [datetime](Get-Date ($guest.signInActivity.lastNonInteractiveSignInDateTime))).TotalDays
            }
            if ($DaysSinceLastLogin -ge $ThresholdDaysAgo -and ($DaysSinceLastNonIntLogin -eq $null -or $DaysSinceLastNonIntLogin -ge $ThresholdDaysAgo)) {
                $InactivePass1 += [pscustomobject]@{
                    UserType                  = $guest.UserType
                    accountEnabled            = $guest.accountEnabled
                    creationType              = $guest.creationType
                    externalUserState         = $guest.externalUserState
                    createdDateTime           = [datetime](Get-Date ($guest.createdDateTime))
                    companyName               = $guest.companyName
                    displayName               = $guest.displayName
                    jobTitle                  = $guest.jobTitle
                    userPrincipalName         = ($guest.userPrincipalName).ToLower()
                    AssignedLicenses          = $guest.AssignedLicenses
                    mail                      = ($guest.mail).ToLower()
                    mailDomain                = ($guest.mail).ToLower() -replace '^.+@'
                    DateLastLogin             = [datetime](Get-Date ($guest.signInActivity.lastSignInDateTime))
                    DaysSinceLastLogin        = $DaysSinceLastLogin
                    DateLastNonIntLogin       = if ($DaysSinceLastNonIntLogin -ne $null) { [datetime](Get-Date ($guest.signInActivity.lastNonInteractiveSignInDateTime)) } else { $null }
                    DaysSinceLastNonIntLogin  = $DaysSinceLastNonIntLogin
                }
            }

            if ($guest.signInActivity.lastSignInDateTime -eq $null -and $guest.signInActivity.lastNonInteractiveSignInDateTime -eq $null) {
                $NeverLoggedIn += $guest

                if ($guest.externalUserState -eq 'PendingAcceptance') {
                    $NotAcceptedInvitation += $guest
                }
            }
        }
    }    
}
$timer.Stop()
Write-Log -Level 0 -Message  "Process Graph-results - Done in $($timer.Elapsed.TotalSeconds) seconds"

Write-Log -Level 0 -Message  "[$($AllGuests.count)]`t  Guests: all guests"
Write-Log -Level 0 -Message  "[$($DisabledGuests.count)]`t    Disabled: Guest users that are disabled"
Write-Log -Level 0 -Message  "[$($EnabledGuests.count)]`t    Enabled: Guest users that are enabled"
Write-Log -Level 0 -Message  "[$($InactivePass1.count)]`t    Inactive: Guests that have not logged in last $ThresholdDaysAgo+ days"
Write-Log -Level 0 -Message  "[$($NeverLoggedIn.count)]`t    No logins: Guests that have not yet logged in"
Write-Log -Level 0 -Message  "[$($NotAcceptedInvitation.count)]`t    Invited: Guests that have not accepted invitation to Entra ID"

$TotalCount = $AllGuests.Count
$DisabledCount = $DisabledGuests.Count
$NeverLoggedInCount = $NeverLoggedIn.Count
$NotAcceptecInvitationCount = $NotAcceptedInvitation.Count
$InactiveCount = $InactivePass1.Count
#Endregion ProcessGuests

#region style
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[System.Windows.Forms.Application]::EnableVisualStyles()

$BackgroundColor = [System.Drawing.Color]::FromArgb(255,220,220,220)
$WrapperBackgroundColor = [System.Drawing.Color]::FromArgb(255,245,245,245)
$LabelFont = New-Object System.Drawing.Font('Calibri Light', '12')
$NarrowFont = New-Object System.Drawing.Font('Calibri Light', '10', [System.Drawing.FontStyle]::Bold)
$ListIconFont = New-Object System.Drawing.Font("Wingdings", '20')
$LabelColor = [System.Drawing.Color]::FromArgb(255,50,50,50)

$gaugelevel1 = [System.Drawing.Color]::FromArgb(255,107,201,104) # green
$gaugelevel2 = [System.Drawing.Color]::FromArgb(255,254,209,54) # yellow
$gaugelevel3 = [System.Drawing.Color]::FromArgb(255,252,133,77) # orange
$gaugelevel4 = [System.Drawing.Color]::FromArgb(255,253,87,99) # red

$StagesLabelYPossition = 30
#endregion style

#region Main form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'InactiveWipe'
$Form.SizeGripStyle = 'Hide'
$Form.FormBorderStyle = 'Fixed3D'
$Form.ClientSize = '1030,170'
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

#Region Start
$Selection = ''

$StartLabel = New-Object System.Windows.Forms.Label
$StartLabel.Location = New-Object Drawing.Point 15,$StagesLabelYPossition
$StartLabel.Text = "Start ->"
$StartLabel.Font = $NarrowFont
$StartLabel.BackColor = $BackgroundColor
$StartLabel.ForeColor = $LabelColor
$StartLabel.ClientSize = '60,20'
$Form.Controls.Add($StartLabel)

$StartText = New-Object System.Windows.Forms.Label
$StartText.Location = New-Object Drawing.Point 15,($StagesLabelYPossition + 20)
$StartText.Text = '' #See Update-Text function
$StartText.BackColor = $BackgroundColor
$StartText.ForeColor = $LabelColor
$StartText.ClientSize = '90,90'
$Form.Controls.Add($StartText)
#Endregion Start

#region tile disabled-guests
$disabledLabel = New-Object System.Windows.Forms.Label
$disabledLabel.Location = New-Object Drawing.Point 115,15
$disabledLabel.Text = 'Disabled'
$disabledLabel.Font = $LabelFont
$disabledLabel.BackColor = $WrapperBackgroundColor
$disabledLabel.ForeColor = $LabelColor
$disabledLabel.ClientSize = '145,20'

$disabledResultListLabel = New-Object System.Windows.Forms.Label
$disabledResultListLabel.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 170),($disabledLabel.Location.Y -2)
$disabledResultListLabel.Text = '2' #Using the Wingdings font, the number 2 represents a list-icon
$disabledResultListLabel.Font = $ListIconFont
$disabledResultListLabel.BackColor = $WrapperBackgroundColor
$disabledResultListLabel.ForeColor = $BackgroundColor
$disabledResultListLabel.ClientSize = '25,25'
$disabledResultListLabel.Add_MouseEnter({
    $disabledResultListLabel.ForeColor = $LabelColor
})
$disabledResultListLabel.Add_MouseLeave({
    $disabledResultListLabel.ForeColor = $BackgroundColor
})
$disabledResultListLabel.add_click({
    Clear-Variable Selection -ErrorAction SilentlyContinue
    $Selection = $DisabledGuests | Out-GridView -Title "Disabled guest users [$($DisabledGuests.count)]" -OutputMode Multiple
    $Selection.userPrincipalName | Set-Clipboard
})

$disabledInfoTextBox = New-Object System.Windows.Forms.RichTextBox
$disabledInfoTextBox.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 45),($disabledLabel.Location.Y + 40)
$disabledInfoTextBox.BackColor = $WrapperBackgroundColor
$disabledInfoTextBox.ClientSize = "140,75"
$disabledInfoTextBox.ReadOnly = $true
$disabledInfoTextBox.BorderStyle = 0

$disabledGauge = New-Object System.Windows.Forms.Label
$disabledGauge.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 6),($disabledLabel.Location.Y + 31)
$disabledGauge.ClientSize = "30,0"
$disabledGauge.BackColor = [System.Drawing.Color]::FromArgb(255,100,200,255)

$disabledBGGauge= New-Object System.Windows.Forms.Label
$disabledBGGauge.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 6),($disabledLabel.Location.Y + 31)
$disabledBGGauge.ClientSize = '30,100'
$disabledBGGauge.BackColor = $BackgroundColor

$disabledBorderGauge= New-Object System.Windows.Forms.Label
$disabledBorderGauge.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 5),($disabledLabel.Location.Y + 30)
$disabledBorderGauge.ClientSize = '32,102'
$disabledBorderGauge.BackColor = [System.Drawing.Color]::FromArgb(255,50,50,50)

$disabledBackground = New-Object System.Windows.Forms.Label
$disabledBackground.Location = New-Object Drawing.Point ($disabledLabel.Location.X - 5),($disabledLabel.Location.Y - 5)
$disabledBackground.ClientSize = '200,150'
$disabledBackground.BackColor = $WrapperBackgroundColor

$Form.Controls.Add($disabledLabel)
$Form.Controls.Add($disabledResultListLabel)
$Form.Controls.Add($disabledInfoTextBox)
$Form.Controls.Add($disabledGauge)
$Form.Controls.Add($disabledBGGauge)
$Form.Controls.Add($disabledBorderGauge)
$Form.Controls.Add($disabledBackground)
#endregion tile disabled-guests

#Region Narrow1
$Narrow1Label = New-Object System.Windows.Forms.Label
$Narrow1Label.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 210),$StagesLabelYPossition
$Narrow1Label.Text = "Narrow ->"
$Narrow1Label.Font = $NarrowFont
$Narrow1Label.BackColor = $BackgroundColor
$Narrow1Label.ForeColor = $LabelColor
$Narrow1Label.ClientSize = '60,20'
$Form.Controls.Add($Narrow1Label)

$Narrow1Text = New-Object System.Windows.Forms.Label
$Narrow1Text.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 210),($StagesLabelYPossition + 20)
$Narrow1Text.Text = '' #See Update-Text function
$Narrow1Text.BackColor = $BackgroundColor
$Narrow1Text.ForeColor = $LabelColor
$Narrow1Text.ClientSize = '90,90'
$Form.Controls.Add($Narrow1Text)
#Endregion Narrow1

#region tile neverLoggedIn
$neverLoggedInLabel = New-Object System.Windows.Forms.Label
$neverLoggedInLabel.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 310),15
$neverLoggedInLabel.Text = 'Never signed in'
$neverLoggedInLabel.Font = $LabelFont
$neverLoggedInLabel.BackColor = $WrapperBackgroundColor
$neverLoggedInLabel.ForeColor = $LabelColor
$neverLoggedInLabel.ClientSize = '145,20'

$neverLoggedInResultListLabel = New-Object System.Windows.Forms.Label
$neverLoggedInResultListLabel.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 170),($neverLoggedInLabel.Location.Y -2)
$neverLoggedInResultListLabel.Text = '2' #Using the Wingdings font, the number 2 represents a list-icon
$neverLoggedInResultListLabel.Font = $ListIconFont
$neverLoggedInResultListLabel.BackColor = $WrapperBackgroundColor
$neverLoggedInResultListLabel.ForeColor = $BackgroundColor
$neverLoggedInResultListLabel.ClientSize = '25,25'
$neverLoggedInResultListLabel.Add_MouseEnter({
    $neverLoggedInResultListLabel.ForeColor = $LabelColor
})
$neverLoggedInResultListLabel.Add_MouseLeave({
    $neverLoggedInResultListLabel.ForeColor = $BackgroundColor
})
$neverLoggedInResultListLabel.add_click({
    Clear-Variable Selection -ErrorAction SilentlyContinue
    $Selection = $NeverLoggedIn | Out-GridView -Title "Never logged in guest users [$($NeverLoggedIn.count)]" -OutputMode Multiple
    $Selection.userPrincipalName | Set-Clipboard
})

$neverLoggedInInfoTextBox = New-Object System.Windows.Forms.RichTextBox
$neverLoggedInInfoTextBox.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 45),($neverLoggedInLabel.Location.Y + 40)
$neverLoggedInInfoTextBox.BackColor = $WrapperBackgroundColor
$neverLoggedInInfoTextBox.ClientSize = "140,75"
$neverLoggedInInfoTextBox.ReadOnly = $true
$neverLoggedInInfoTextBox.BorderStyle = 0

$neverLoggedInGauge = New-Object System.Windows.Forms.Label
$neverLoggedInGauge.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 6),($neverLoggedInLabel.Location.Y + 31)
$neverLoggedInGauge.ClientSize = "30,0"
$neverLoggedInGauge.BackColor = [System.Drawing.Color]::FromArgb(255,100,200,255)

$neverLoggedInBGGauge= New-Object System.Windows.Forms.Label
$neverLoggedInBGGauge.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 6),($neverLoggedInLabel.Location.Y + 31)
$neverLoggedInBGGauge.ClientSize = '30,100'
$neverLoggedInBGGauge.BackColor = $BackgroundColor

$neverLoggedInBorderGauge= New-Object System.Windows.Forms.Label
$neverLoggedInBorderGauge.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 5),($neverLoggedInLabel.Location.Y + 30)
$neverLoggedInBorderGauge.ClientSize = '32,102'
$neverLoggedInBorderGauge.BackColor = [System.Drawing.Color]::FromArgb(255,50,50,50)

$neverLoggedInBackground = New-Object System.Windows.Forms.Label
$neverLoggedInBackground.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X - 5),($neverLoggedInLabel.Location.Y - 5)
$neverLoggedInBackground.ClientSize = '200,150'
$neverLoggedInBackground.BackColor = $WrapperBackgroundColor

$Form.Controls.Add($neverLoggedInLabel)
$Form.Controls.Add($neverLoggedInResultListLabel)
$Form.Controls.Add($neverLoggedInInfoTextBox)
$Form.Controls.Add($neverLoggedInGauge)
$Form.Controls.Add($neverLoggedInBGGauge)
$Form.Controls.Add($neverLoggedInBorderGauge)
$Form.Controls.Add($neverLoggedInBackground)
#endregion tile neverLoggedIn

#Region Narrow2
$Narrow2Label = New-Object System.Windows.Forms.Label
$Narrow2Label.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 210),$StagesLabelYPossition
$Narrow2Label.Text = "Narrow ->"
$Narrow2Label.Font = $NarrowFont
$Narrow2Label.BackColor = $BackgroundColor
$Narrow2Label.ForeColor = $LabelColor
$Narrow2Label.ClientSize = '60,20'
$Form.Controls.Add($Narrow2Label)

$Narrow2Text = New-Object System.Windows.Forms.Label
$Narrow2Text.Location = New-Object Drawing.Point ($neverLoggedInLabel.Location.X + 210),($StagesLabelYPossition + 20)
$Narrow2Text.Text = '' #See Update-Text function
$Narrow2Text.BackColor = $BackgroundColor
$Narrow2Text.ForeColor = $LabelColor
$Narrow2Text.ClientSize = '90,100'
$Form.Controls.Add($Narrow2Text)
#Endregion Narrow2

#region tile inactive-guests
$inactiveLabel = New-Object System.Windows.Forms.Label
$inactiveLabel.Location = New-Object Drawing.Point ($disabledLabel.Location.X + 620),15
$inactiveLabel.Text = 'Inactive'
$inactiveLabel.Font = $LabelFont
$inactiveLabel.BackColor = $WrapperBackgroundColor
$inactiveLabel.ForeColor = $LabelColor
$inactiveLabel.ClientSize = '145,20'

$inactiveResultListLabel = New-Object System.Windows.Forms.Label
$inactiveResultListLabel.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 170),($inactiveLabel.Location.Y -2)
$inactiveResultListLabel.Text = '2' #Using the Wingdings font, the number 2 represents a list-icon
$inactiveResultListLabel.Font = $ListIconFont
$inactiveResultListLabel.BackColor = $WrapperBackgroundColor
$inactiveResultListLabel.ForeColor = $BackgroundColor
$inactiveResultListLabel.ClientSize = '25,25'
$inactiveResultListLabel.Add_MouseEnter({
    $inactiveResultListLabel.ForeColor = $LabelColor
})
$inactiveResultListLabel.Add_MouseLeave({
    $inactiveResultListLabel.ForeColor = $BackgroundColor
})
$inactiveResultListLabel.add_click({
    Clear-Variable Selection -ErrorAction SilentlyContinue
    $Selection = $InactivePass1 | Out-GridView -Title "Inactive guest users [$($InactivePass1.count)]" -OutputMode Multiple
    $Selection.userPrincipalName | Set-Clipboard
})

$inactiveInfoTextBox = New-Object System.Windows.Forms.RichTextBox
$inactiveInfoTextBox.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 45),($inactiveLabel.Location.Y + 40)
$inactiveInfoTextBox.BackColor = $WrapperBackgroundColor
$inactiveInfoTextBox.ClientSize = "140,75"
$inactiveInfoTextBox.ReadOnly = $true
$inactiveInfoTextBox.BorderStyle = 0

$inactiveGauge = New-Object System.Windows.Forms.Label
$inactiveGauge.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 6),($inactiveLabel.Location.Y + 31)
$inactiveGauge.ClientSize = "30,0"
$inactiveGauge.BackColor = [System.Drawing.Color]::FromArgb(255,100,200,255)

$inactiveBGGauge= New-Object System.Windows.Forms.Label
$inactiveBGGauge.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 6),($inactiveLabel.Location.Y + 31)
$inactiveBGGauge.ClientSize = '30,100'
$inactiveBGGauge.BackColor = $BackgroundColor

$inactiveBorderGauge= New-Object System.Windows.Forms.Label
$inactiveBorderGauge.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 5),($inactiveLabel.Location.Y + 30)
$inactiveBorderGauge.ClientSize = '32,102'
$inactiveBorderGauge.BackColor = [System.Drawing.Color]::FromArgb(255,50,50,50)

$inactiveBackground = New-Object System.Windows.Forms.Label
$inactiveBackground.Location = New-Object Drawing.Point ($inactiveLabel.Location.X - 5),($inactiveLabel.Location.Y - 5)
$inactiveBackground.ClientSize = '200,150'
$inactiveBackground.BackColor = $WrapperBackgroundColor

$Form.Controls.Add($inactiveLabel)
$Form.Controls.Add($inactiveResultListLabel)
$Form.Controls.Add($inactiveInfoTextBox)
$Form.Controls.Add($inactiveGauge)
$Form.Controls.Add($inactiveBGGauge)
$Form.Controls.Add($inactiveBorderGauge)
$Form.Controls.Add($inactiveBackground)
#endregion tile inactive-guests

#Region Result
$ResultLabel = New-Object System.Windows.Forms.Label
$ResultLabel.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 210),$StagesLabelYPossition
$ResultLabel.Text = "Result:"
$ResultLabel.Font = $NarrowFont
$ResultLabel.BackColor = $BackgroundColor
$ResultLabel.ForeColor = $LabelColor
$ResultLabel.ClientSize = '60,20'
$Form.Controls.Add($ResultLabel)

$ResultText = New-Object System.Windows.Forms.Label
$ResultText.Location = New-Object Drawing.Point ($inactiveLabel.Location.X + 210),($StagesLabelYPossition + 20)
$ResultText.Text = '' #See Update-Text function
$ResultText.BackColor = $BackgroundColor
$ResultText.ForeColor = $LabelColor
$ResultText.ClientSize = '90,90'
$Form.Controls.Add($ResultText)
#Endregion Result

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