
Configuration WebServer
{
    param(
	[parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string] $NodeNames,
	[string] $AcctKey = "gE7MNh3+HPF1nJAhtRhzDSqJWgizpE/g572kZ8s4D0jAhh+ocpKhP4NGRURAyaqq5CUXhnru7FwngrFqRhD9tg=="
    )

    Import-DscResource -Name Service -Module PsDesiredStateConfiguration

    [String] $StorageAccountName = "linkedinautomation"
    [String] $StorageAccountUserName = "Azure\" + $StorageAccountName
    $secureacctKey = $AcctKey | ConvertTo-SecureString -AsPlainText -Force
    $myStorageCredentials = New-Object System.Management.Automation.PSCredential ($StorageAccountUserName, $secureacctKey)
    
    Node $NodeNames
    {
		WindowsFeature DSCServiceFeature
		{
			Ensure = "Present"
			Name   = "DSC-Service"
		}
        
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
            SourcePath =  "\\linkedinautomation.file.core.windows.net\configurevms\index.htm"
            DestinationPath = "C:\inetpub\wwwroot\index.htm"
            Type = "File"
        }
    }
}
