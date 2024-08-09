# InactiveWipe
A script to help stay in control of guest access in Entra ID

![InactiveWipe](https://github.com/user-attachments/assets/58724cce-7cfe-4d79-afbf-b907687381d3)


Parameter | Description
--- | ---
tenantId (mandatory) | Tenant id 'string'
appId (mandatory) | Application id 'string'
appSecret (mandatory) | Application secret 'string'
thresholdDaysAgo | Number of days without activity for guests to be consideres inactive. Default value is 180 'int'
