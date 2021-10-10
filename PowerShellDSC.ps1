Configuration WebServer
{
    param(
    [Parameter(Mandatory=$true)]
    [string] $NodeNames = "localhost",
    [string] $AcctKey = "4PJREBT6kPMh9ejQwIhoU+vmOWdd7WYCVIhDEbttPPZVln8HerqOCQR+PTXlSMd0AZd4tVdRPIy/TEfos4aU9Q=="
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    [String] $StorageAccountName = "linkedinautomation"
    $secureacctKey = $AcctKey | ConvertTo-SecureString -AsPlainText -Force
    $myStorageCredentials = New-Object System.Management.Automation.PSCredential ($StorageAccountName, $secureacctKey)
    
    Node $NodeNames
    {
        # Make sure that IIS is installed
        WindowsFeature IIS
        {
            Name = 'web-server'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }

        # All the IISManagement Tools are also intalled
        WindowsFeature IISMgmt
        {
            Ensure = "Present"
            Name = "Web-Mgmt-Tools"
        }

        WindowsFeature ASPNet45
        {
            Name = "Web-ASP-Net45"
            Ensure = "Present"
        }

        File ASPNetWebsite
        {
            Ensure = "Present"
            Credential = $myStorageCredentials
            SourcePath =  "\\linkedinautomation.file.core.windows.net\configurevms"
            DestinationPath = "C:\inetpub\wwwroot"
            Recurse = $true
            Type = "Directory"
        }
    }
}
