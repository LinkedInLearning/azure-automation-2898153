#This function creates an Azure AD Service Principal
#CreatedBy: Neeraj Kumar
#Date: December 2020
function CreateServicePrincipal {
  param($username, $password)

	$credproperties = @{
		StartDate = Get-Date
		EndDate = Get-Date -Year 2024
		Password = $password
  }
  $cred= New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property $credproperties
  $sp = New-AzAdServicePrincipal -DisplayName $username -PasswordCredential $cred
}
