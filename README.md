# InactiveWipe
A graphical interface script to help stay in control of guest access in Entra ID


### 🟡Features
The script will identify ...
* Disabled guests
* Guests that never logged in and/or did not accept the invitation
* Guests that have no logins for the last 180 days (interactive or noninteractive)

![InactiveWipe](https://github.com/user-attachments/assets/58724cce-7cfe-4d79-afbf-b907687381d3)


### 🟡Prerequisites
* A registered app with the `User Read All` Graph permission
See this [step-by-step guide](https://github.com/erlwes/InactiveWipe/blob/main/AppRegistration.md)


### 🟡Usage
Running the script
```PowerShell
.\InactiveWipe.ps1 -tenantId <your-tenant-id> -appId <your-app-id> -appSecret <your-app-secret>
```

To inspect the results, click the "list"-icons to view the findings:

![image](https://github.com/user-attachments/assets/ba21617c-2e16-4b7e-9344-374f7b105c4a)

This will open the results in a gridview, allowing you to inspect the results and select multiple guests. When you click "Ok" the selected guests UserPrincipalNames are copied to the clipboard.

Parameter | Description
--- | ---
tenantId (mandatory) | Your Entra ID tenant ID 'string'
appId (mandatory) | The application ID for your registered application in Azure AD 'string'
appSecret (mandatory) | The client secret for your registered application
thresholdDaysAgo | Number of days without activity for guests to be consideres inactive. Default is 180 days 'int'


### 🟡Sanity checks

**Disabled users**
Before removing disabled users, check their last sign-in activity first

**Never logged inn**
Before deleting og disabling these users, make sure they where not recently invited/added


### 🟡I found guest that can be wiped, now what?
1. Use the tool to identify and select users for removal (UPN copied to clipboard when clicking ok from gridview)
2. Go to User blade in Entra AD portal
3. Select "Bulk operations" and "Bulk delete"
4. Download example CSV
5. Open the example CSV, paste guest-users UPN, save the file
6. Upload the file to "bulk delete users" and type "Yes" to contine.
7. Click "Submit"
