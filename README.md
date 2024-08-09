# InactiveWipe
A script to help stay in control of guest access in Entra ID

## Features
The script will identify ...
* Disabled guests
* Guests that never logged in and/or did not accept the invitation
* Guests that have no logins for the last 180 days (interactive or noninteractive)

## Looks like this
![InactiveWipe](https://github.com/user-attachments/assets/58724cce-7cfe-4d79-afbf-b907687381d3)

## Prerequisites
* A registered app with the `User Read All` Graph permission
See this [step-by-step guide](https://github.com/erlwes/InactiveWipe/blob/main/AppRegistration.md)

## Usage

Running the script
```PowerShell
.\InactiveWipe.ps1 -tenantId <your-tenant-id> -appId <your-app-id> -appSecret <your-app-secret>
```

To inspect the results, click the "list"-icons to view the findings:


Parameter | Description
--- | ---
tenantId (mandatory) | Your Entra ID tenant ID 'string'
appId (mandatory) | The application ID for your registered application in Azure AD 'string'
appSecret (mandatory) | The client secret for your registered application
thresholdDaysAgo | Number of days without activity for guests to be consideres inactive. Default is 180 days 'int'
