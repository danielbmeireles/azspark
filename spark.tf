provider "azurerm" {
    version = "=1.27"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
    name     = "sparkResourceGroup"
    location = "West Europe"

    tags = {
        environment = "Tech Challenge - DTB Hub"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "sparkVNET"
    address_space       = ["192.168.0.0/16"]
    location            = "West Europe"
    resource_group_name = "${azurerm_resource_group.rg.name}"
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "sparkSubnet"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.vnet.name}"
    address_prefix       = "192.168.1.0/24"
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
    name                         = "sparkPublicIP"
    location                     = "West Europe"
    resource_group_name          = "${azurerm_resource_group.rg.name}"
    public_ip_address_allocation = "dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "sparkNetworkSecurityGroup"
    location            = "West Europe"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "WWW"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080-8081"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
    name                      = "sparkNIC-${count.index}"
    location                  = "West Europe"
    resource_group_name       = "${azurerm_resource_group.rg.name}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                          = "sparkNICConfig-${count.index}"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
    name                  = "sparkVM-${count.index}"
    location              = "West Europe"
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
    vm_size               = "Standard_B1ms"
    count                 = 3

    storage_os_disk {
        name              = "sparkOsDisk-${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "sparkVM"
        admin_username = "sparkadmin"
        admin_password = "spark975!#_"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

}
