# Step 1: Log in to Azure Portal
1. Go to Entra Portal.
2. Sign in with your Azure account that has permissions to manage Entra ID.

# Step 2: Create an App Registration
1. In the Azure Portal, navigate to Microsoft Entra ID from the left-hand menu.
2. In the Manage-section, select App registrations.
3. Click on New registration at the top of the page.
4. Fill in the following details:
5. Name: Enter a name for your app (e.g., InactiveGuestCleaner)
6. Supported account types: Choose the appropriate option based on your needs (usually, "Accounts in this organizational directory only" is selected).
7. Redirect URI (optional): You can leave this blank for this script, as it is not a web or mobile application.
8. Click Register to create the application.

# Step 3: Configure API Permissions
1. After the app registration is created, you will be taken to the Overview page for the app.
2. In the left-hand menu, expand "Manage" and select API permissions.
3. Click on Add a permission.
4. Under Microsoft APIs, select Microsoft Graph.
5. Choose Application permissions (not Delegated permissions).
6. Search for and select the following permissions:
7. User.Read.All: Read all users' full profiles.
8. After selecting the permissions, click on Add permissions.
9. Back on the API permissions page, click the Grant admin consent for {Your Tenant Name} button. This will grant the necessary permissions across the tenant. Confirm by clicking Yes in the prompt.

# Step 4: Generate a Client Secret
1. In the left-hand menu, select Certificates & secrets.
2. Under Client secrets, click New client secret.
3. Provide a description for the client secret (e.g., InactiveGuestCleanerSecret).
4. Set an expiration period for the client secret (e.g., 6 months, 12 months, or 24 months).
5. Click Add to create the client secret.
6. Important: Copy the generated client secret value immediately, as you will not be able to view it again. Store this securely, as it will be needed to run the script.

# Step 5: Retrieve the Tenant ID, Client ID, and Client Secret
1. Go back to the Overview page of your app registration.
2. Note down the Application (client) ID and Directory (tenant) ID. These values will be used as $appId and $tenantId respectively in your script.
3. Use the previously copied Client secret value as $appSecret in your script.

Good to go :)
