Configuration WebServer
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration -Name Service, File, Registry
    Import-DSCResource -Name WindowsFeature
    
    
    # declare the VMs as nodes for which the configuration will happen. This can be parameterized using parantheses as comma separated names
    # Configure the first node. This is the first VM
    Node VM1_Windows
    {
        # Make sure that IIS is installed
        WindowsFeature IIS
        {
            Name = 'web-server'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }
        File index
        {
            Script ScriptExample
            {
                SetScript = {
                    $vaStorageAccount = Get-AutomationVariable -Name "StorageAccount"
                    $StartTime = Get-Date
                    $EndTime = $startTime.AddHours(1.0)
                    $stgAccount = Get-AzStorageAccount -Name $vaStorageAccount -ResourceGroupName $vResourceGroupname
                    $SASToken = New-AzStorageAccountSASToken -Service 'Blob' -ResourceType Container,Object -Permission "racwdlup" -startTime $StartTime -ExpiryTime $EndTime -Context $stgAccount.Context
                    $stgcontext = New-AzStorageContext -storageAccountName $stgAccount.StorageAccountName -SasToken $SASToken

                    $Path = "$env:TEMP\index.htm"
                    Remove-Item $Path -ErrorAction SilentlyContinue

                    $blob = Get-AzStorageBlob -Container 'createvm' -Blob 'index.htm' -Context $stgcontext
                    $tmp = Get-AzStorageBlobContent -CloudBlob $blob.ICloudBlob -Destination $Path -Context $stgcontext #.Context.FileEndPoint + "atcslfileshare"
                }
            }
            Ensure = "Present" # Ensure the directory is Present on the target node.
            Type = "File" # The default is File.
            SourcePath = $Path
            DestinationPath = "C:\inetpub\wwwroot\index.htm"
            DependsOn = '[WindowsFeature]IIS'
        }
    }
}
