# Overview
This project uses Azure Automation to automatically install Nessus Agents onto running virtual machines in an Azure Subscription

# Setting Up Azure
In order for this project to run there are several things that need to be setup in Azure:
* Create an Automation Account
* Give permissions to subscription for Automation Account
* Install Az modules in Automation Account
* Configure an Azure Storage Account
* Configure Variables in Automation Account
* Create Runbook
* Schedule the Runbook

Once these are setup, the Automation Account can regularly run and make sure any systems without a Nessus Agent have it installed.

## Azure Automation Account
Create an Automation Account in the Azure subscription where you want to run the script

## Set up permissions for Automation Account app ID
Make sure the app ID being used by the Automation runbook script has rights to the subscription:
* Microsoft.Compute/locations/runCommands/read
* Microsoft.Compute/virtualMachines/runCommand/action

If you get any errors about a module not being installed, be sure to install the module in the Automation Account to allow Az.Compute to be imported

## Install modules in Automation Account
In the automation account is a "Modules" blade.  Select that and confirm the "Az" modules are installed, include "Az.Compute"

## Configure an Azure Storage Account
Create an Azure Storage Account and upload the InstallNessusAgent scripts to it.
Also download the Nessus Agent binaries that you will need to install.

## Set up variables in Automation Account
Make sure these variables are set up:
* NessusLinkingKey - The Tenable.io linking key for agents
* NessusUbuntuInstallBinary - The URL that holds the Nessus Agent installer for Ubuntu x64
* NessusUbuntuInstallScript - The URL that holds the InstallNessusAgent.ubuntu.sh script from this project.  
* NessusWindowsInstallBinary - The URL that holds the Nessus Agent installer for Windows x64
* NessusWindowsInstallScript - The URL that holds the InstallNessusAgent.ps1 script from this project.  

## Create the Runbook

## Schedule the Runbook
This is more your organizational preference.  I have it running daily at 8am, but you could run it at a different time or frequency to fit your needs.

# Reference
Some useful references that were used in the creation of this project

* https://docs.microsoft.com/en-us/azure/virtual-machines/windows/run-command#limiting-access-to-run-command