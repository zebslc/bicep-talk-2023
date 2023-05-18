# Introduction 
Use this as a non-trivial, basic example for creating your own infrastructure as code using Bicep

I have added links to the relevant documentation for each resource to help you adjust it to match your own requirements.
As with anything all risks are your own and if in doubt check with a security expert and your own company policies before deploying anything to production.
The slideshow presentation has been included in the folder for your reference.
This repo will be updated with the second presentation containing all the devops pipeline changes at a later date.

# Getting Started
1.	Installation process 
    - Install VS Code, Get the Bicep and PlantUML extensions
    - https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install
    - Ensure you have the latest version of Azure CLI installed https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

2.  Manually deploying your first environment
    - Log into Azure CLI with `az login`
    - Choose which subscription you wish to test this on with `az account set --subscription 99999-9999-9999-99999-99999999`
    - Initiate the creation with `az deployment sub create --location uksouth --template-file main.bicep --parameters location=uksouth baseApplicationName={<10 character base name here} environmentName=dev environmentNumber=1 countryCode=GB createB2C=true`.  
        - More info about running from the CLI here https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli
        - If you wish to do a what-if use the following https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if?tabs=azure-powershell%2CCLI
    - Each of the parameters has a description in main.bicep
    - Note, you can only set `createB2C` to true once per subscription.  If you wish to test this again you will need to delete the B2C tenant and all associated resources first. Setting it to false will not delete the resources but will let you continue re-creating everything else.
    - Open [Access control (IAM)] menu within the Azure portal and for experimental purposes add your user to the Owner role for the subscription.  This will allow you to see all the resources created and make changes to them.  In production you would want to use a more granular approach to permissions.  Also set the KeyVault administrator to your account so you can see the secrets created.
    - Enjoy!

3. Automated deployment
    - More information will be added in talk 2

3.	Latest releases
    - This first release is the manual deployment version.  Use it to learn about how to create resources and use modules

4. Additional info links
    - Naming convention for resources https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

# Contribute
If you have improvements to these scripts that will help others or can see things I have done that could be improved/made safer then please just submit a PR :-)
