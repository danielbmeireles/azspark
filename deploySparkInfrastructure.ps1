# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-powershell
# https://www.jorgebernhardt.com/create-multiple-identical-vms-at-once-with-azure-powershell/

# Parâmetros Globais
$locationName = "West Europe"
$resourceGroupName = "sparkResourceGroup"

$networkName = "sparkVNET"
$nicName = "sparkNIC-"

$computerName = @("master","slave1","slave2")
$computerSize = "Standard_B1ms"
$publisherName = "Canonical"
$offer = "UbuntuServer"
$skus = "18.04-LTS"

# Criando um novo 'Resource Group'
New-AzResourceGroup -Name $resourceGroupName -Location $locationName

# Criando uma 'Subnet'
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name "sparkSubnet" -AddressPrefix 192.168.1.0/24

# Criando uma 'Virtual Network'
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName `
                             -Location $locationName `
                             -Name $networkName `
                             -AddressPrefix 192.168.0.0/16 `
                             -Subnet $subnetConfig

# Criando uma 'Inbound Network Security Group Rule' para a porta 22 (SSH)
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name "sparkNetworkSecurityGroupRuleSSH" `
                                              -Protocol "Tcp" `
                                              -Direction "Inbound" `
                                              -Priority 1000 `
                                              -SourceAddressPrefix * `
                                              -SourcePortRange * `
                                              -DestinationAddressPrefix * `
                                              -DestinationPortRange 22 `
                                              -Access "Allow"

# Criando uma 'Inbound Network Security Group Rule' para a porta 8080/8081 (Spark Dashboard)
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig -Name "sparkNetworkSecurityGroupRuleWWW" `
                                              -Protocol "Tcp" `
                                              -Direction "Inbound" `
                                              -Priority 1001 `
                                              -SourceAddressPrefix * `
                                              -SourcePortRange * `
                                              -DestinationAddressPrefix * `
                                              -DestinationPortRange 8080-8081 `
                                              -Access "Allow"

# Criando um 'Network Security Group'
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
                                  -Location $locationName `
                                  -Name "sparkNetworkSecurityGroup" `
                                  -SecurityRules $nsgRuleSSH,$nsgRuleWeb

# Definindo as credenciais de acesso
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("sparkadmin", $securePassword)

# Criando os nós do cluster Spark
$computerName | ForEach-Object {
  $PIP = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName `
                              -Location $locationName `
                              -AllocationMethod Static `
                              -IdleTimeoutInMinutes 4 `
                              -Name ("sparkNameDNS-"+$_)

 $NIC = New-AzNetworkInterface -Name ($nicName+$_) `
                               -ResourceGroupName $resourceGroupName `
                               -Location $locationName `
                               -SubnetId $vnet.Subnets[0].Id `
                               -PublicIpAddressId $PIP.Id `
                               -NetworkSecurityGroupId $nsg.Id

 $VirtualMachine = New-AzVMConfig -VMName $_ `
                                  -VMSize $computerSize
                                  
 $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
                                           -Linux `
                                           -ComputerName $_ `
                                           -Credential $cred `
                                           -DisablePasswordAuthentication

 $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine `
                                            -Id $NIC.Id
 
 $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
                                       -PublisherName $publisherName `
                                       -Offer $offer `
                                       -Skus $skus `
                                       -Version latest

$sshPublicKey = cat ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey -VM $VirtualMachine `
                     -KeyData $sshPublicKey `
                     -Path "/home/sparkadmin/.ssh/authorized_keys"
 
 New-AzVM -ResourceGroupName $resourceGroupName `
          -Location $locationName `
          -VM $VirtualMachine `
          -Verbose
}