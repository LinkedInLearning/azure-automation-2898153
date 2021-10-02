#Created By: Neeraj Kumar
#Date: December 2020
#This script will be called by the initiate watcher process runbook and performs the deployment of the workloads as per the parameters passed.
#It will use theshared resources like credentials and variables.
param([string[]] $vmdetail)

#Fetch the automation service principal credentials
$global:spCred = Get-AutomationPSCredential -Name 'Creds'

#Fetch tenantID from Automation variables
$global:tenantid = Get-AutomationVariable -Name 'TenantID'

#Fetch tenantID from Automation variables
$global:vnet = Get-AutomationVariable -Name 'vNet'
#Fetch Security Group Name from Automation variables
$global:NSGName = Get-AutomationVariable -Name 'nsg'

#initialize the subnet variable
$global:subnetname = ''
$global:subnetid = ''

function Load-VMDetails {
    #$vmdetails = $Data | Out-String #| ConvertFrom-Json
    #foreach($vmdetail in $vmdetails) {
        $vmname = $vmdetail[0]
        $cname = $vmdetail[1]
        $loc = $vmdetail[2]
        $rg =  $vmdetail[3]
        $LocalAdminUser = $vmdetail[4]
        $LocalAdminSecurePassword = $vmdetail[5]
        $Size = $vmdetail[6]
        $pubName = $vmdetail[7]
        $offer = $vmdetail[8]
        $sku = $vmdetail[9]
        
        CreateVM $vmname $cname $loc $rg $LocalAdminUser $LocalAdminSecurePassword $Size $sku $pubName $offer
    #}
    
}

#Connect to Azure Tenant
#Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantid

#Create the new virtual machine
function CreateVM ($vmName, $computername, $location, $resourcegroup, $vmLocalAdminUser, $vmLocalAdminPassword, $vmSize, $SKUs, $publisher, $offering){

    $vmLocalAdminSecurePassword = ConvertTo-SecureString $vmLocalAdminPassword -AsPlainText -Force

    #Set the Public IP Address Name
    $pubIP = 'pip-' + $vmName
    $pip = New-AzPublicIpAddress -ResourceGroupName $resourcegroup -Name $pubIP -Location $location -AllocationMethod 'static' -SKU 'Standard'

    $Credential = New-Object System.Management.Automation.PSCredential ($vmLocalAdminUser, $vmLocalAdminSecurePassword)

    $nsgid = (Get-AzNetworkSecurityGroup -Name $global:NSGName -ResourceGroupName $resourcegroup).Id
    $nicdetail = 'nic_' + $vmName

    $NIC = New-AzNetworkInterface -Name $nicdetail -ResourceGroupName $resourcegroup -Location $location -SubnetId $global:subnetid `
    -NetworkSecurityGroupId $nsgid -PublicIpAddressId $pip.Id

    $VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $vmSize
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $computername -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $publisher -Offer $offering -Skus $SKUs -Version latest

    New-AzVM -ResourceGroupName $resourcegroup -VM $VirtualMachine -Location $location

}

# Determine the subnet details from the vNet
function Get-Subnet{
#Get All Subnets in this VNET
    $VNET = Get-AzVirtualNetwork -Name $global:vnet
	$AZSubnets = $VNET | Get-AzVirtualNetworkSubnetConfig
	ForEach ($Subnet in $AZSubnets) {
		#Used for counting later
		$SubnetConfigured = $Subnet | Select-Object -ExpandProperty IpConfigurations

		#Gets the mask from the IP configuration (I.e 10.0.0.0/24, turns to just "24")
		$AddressPrefix = $Subnet.AddressPrefix
		$Mask = $AddressPrefix.substring($AddressPrefix.Length - 2,2)

		#Depends on the mask, sets how many available IP's we have - Add more if required
		switch ($Mask) {
			'29' { $AvailableAddresses = "3" }
			'28' { $AvailableAddresses = "11" }
			'27' { $AvailableAddresses = "27" }
			'26' { $AvailableAddresses = "59" }
			'25' { $AvailableAddresses = "123" }
			'24' { $AvailableAddresses = "251" }
			'23' { $AvailableAddresses = "507" }
			'22' { $AvailableAddresses = "1019" }
			'21' { $AvailableAddresses = "2043" }
			'20' { $AvailableAddresses = "4091" }
			'19' { $AvailableAddresses = "8186" }
			'18' { $AvailableAddresses = "16378" }
			'17' { $AvailableAddresses = "32763" }
		    	'16' { $AvailableAddresses = "65531" }
			}

		#Get the number of IP's left to be consumed

        $IpsLeft = [int]$AvailableAddresses - $SubnetConfigured.Count
        if ($IpsLeft -gt 0)
        {
            $global:subnetname = $Subnet.Name
            $global:subnetid = $Subnet.Id
        }
        else{
            $lastsubnetname = 'subnetVM' + $AZSubnets.Count + 1

            [int]$AddressPrefixCounter = $AddressPrefix.substring($AddressPrefix.Length - 6, 1) + 1
            
            $lastsubnetAddressPrefix = $AddressPrefix.substring(0, $AddressPrefix.Length - 6) + [string]$AddressPrefixCounter + '.0/' + $Mask.substring($Mask.Length - 2,2)

            $Subnet = Add-AzVirtualNetworkSubnetConfig -Name $lastsubnetname -VirtualNetwork $vnet -AddressPrefix $lastsubnetAddressPrefix
            $virtualNetwork | Set-AzVirtualNetwork
            $global:subnetname = $lastsubnetname
            $global:subnetid = $Subnet.Id
        }
    }
}

# load the excel file to read the details for VM Creation
Get-Subnet
Load-VMDetails