# InactiveWipe
A graphical interface script to help stay in control of guest access in Entra ID.
The tool helps identify disabled, inactive and never-used guest users.


### 🟡 The GUI
A graphical interface displays the results.

![image](https://github.com/user-attachments/assets/571e31c8-2f4a-497e-940f-187ff52d1d2f)


### 🟡 View results or save to CSV
The "save"-icon lets you save results to CSV (for bulk-operations in Entra ID?)
To inspect the results, click the "list"-icons in GUI. If you have a selection when clicking "OK", the users UPN is copied to clipboard for bulk delete/disable operations.

The script is read-only and will **not** disable or delete any users.

![image](https://github.com/user-attachments/assets/644e3577-ed85-41bf-9bcc-65a333b23968)


### 🟡 Console
Errors and some info is outputed to console when running.

![image](https://github.com/user-attachments/assets/35e2d01a-1baf-449f-a04d-c6fe2b147f58)


### 🟡 Prerequisites
* A registered app with the `User Read All` and `AuditLog.Read.All` Graph permissions
See this [step-by-step guide](https://github.com/erlwes/InactiveWipe/blob/main/AppRegistration.md)

### 🟡 Install
`Install-Script -Name InactiveWipe`

### 🟡 Usage
Running the script
```PowerShell
.\InactiveWipe.ps1 -TenantId <your-tenant-id> -AppId <your-app-id> -AppSecret <your-app-secret>
```

Parameter | Description
--- | ---
TenantId (mandatory) | Your Entra ID tenant ID 'string'
AppId (mandatory) | The application ID for your registered application in Azure AD 'string'
AppSecret (mandatory) | The client secret for your registered application
ThresholdDaysAgo | Number of days without activity for guests to be consideres inactive. Default is 180 days 'int'


### 🟡 Considerations
* Before removing disabled users, check their last sign-in activity first
* Before removing users that have never signed in, make sure they where not recently invited/added (createdDateTime)
* Don't store ClientSecret/Application Secret in script. Ideally, load it from a password manager, SecretStore or alike. If not, at least close process and clear command history

### 🟡 I found guest that can be wiped, now what?
If you are not familiar with PowerShell to perform batch operations like remove and disable/block of users in Entra ID, you can use bulk operations in the Entra AD portal.

1. Use the tool to identify and select users for removal (UPN copied to clipboard when clicking ok from gridview)
2. Go to User blade in Entra AD portal
3. Select "Bulk operations" and "Bulk delete"
4. Download example CSV
5. Open the example CSV, paste guest-users UPN, save the file
6. Upload the file to "bulk delete users" and type "Yes" to contine.
7. Click "Submit"
