provider "azurerm" {
    version = "=1.27"
}

resource "azurerm_resource_group" "rg" {
    name     = "sparkResourceGroup"
    location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
    name                = "sparkVNET"
    address_space       = ["192.168.0.0/16"]
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
 name                 = "sparkSubnet"
 resource_group_name  = "${azurerm_resource_group.rg.name}"
 virtual_network_name = "${azurerm_virtual_network.vnet.name}"
 address_prefix       = "192.168.1.0/24"
}

resource "azurerm_public_ip" "publicip" {
 name                         = "sparkPublicIP"
 location                     = "${azurerm_resource_group.rg.location}"
 resource_group_name          = "${azurerm_resource_group.rg.name}"
 public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_security_group" "nsg" {
    name                = "sparkNetworkSecurityGroup"
    location            = "${azurerm_resource_group.rg.location}"
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
resource "azurerm_network_interface" "nic" {
    count               = 3
    name                = "sparkNIC-${count.index}"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    ip_configuration {
        name                          = "sparkNICConfig"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }
}

resource "azurerm_virtual_machine" "vm" {
    count                 = 3
    name                  = "sparkVM-${count.index}"
    location              = "${azurerm_resource_group.rg.location}"
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
    vm_size               = "Standard_B1ms"

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    storage_os_disk {
        name              = "sparkOSDisk-${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
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
