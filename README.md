██╗███╗░░██╗░█████╗░░█████╗░████████╗██╗██╗░░░██╗███████╗░██╗░░░░░░░██╗██╗██████╗░███████╗
██║████╗░██║██╔══██╗██╔══██╗╚══██╔══╝██║██║░░░██║██╔════╝░██║░░██╗░░██║██║██╔══██╗██╔════╝
██║██╔██╗██║███████║██║░░╚═╝░░░██║░░░██║╚██╗░██╔╝█████╗░░░╚██╗████╗██╔╝██║██████╔╝█████╗░░
██║██║╚████║██╔══██║██║░░██╗░░░██║░░░██║░╚████╔╝░██╔══╝░░░░████╔═████║░██║██╔═══╝░██╔══╝░░
██║██║░╚███║██║░░██║╚█████╔╝░░░██║░░░██║░░╚██╔╝░░███████╗░░╚██╔╝░╚██╔╝░██║██║░░░░░███████╗
╚═╝╚═╝░░╚══╝╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═╝░░░╚═╝░░░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░░░░╚══════╝

A script to help stay in control of guest access in Entra ID

The script will identify ...
* Disabled guests
* Guests that never logged in and/or did not accept the invitation
* Guests that have no logins for the last 180 days (interactive or noninteractive)

![InactiveWipe](https://github.com/user-attachments/assets/58724cce-7cfe-4d79-afbf-b907687381d3)

# Prerequisites

### Microsoft Graph API Permissions
The script requires access to Microsoft Graph API. Ensure that you have the necessary API permissions set up for your application.



# Usage

### Running the script
```PowerShell
.\InactiveWipe.ps1 -tenantId <your-tenant-id> -appId <your-app-id> -appSecret <your-app-secret>
```

### Parameters
Parameter | Description
--- | ---
tenantId (mandatory) | Your Entra ID tenant ID 'string'
appId (mandatory) | The application ID for your registered application in Azure AD 'string'
appSecret (mandatory) | The client secret for your registered application
thresholdDaysAgo | Number of days without activity for guests to be consideres inactive. Default is 180 days 'int'
