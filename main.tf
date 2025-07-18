# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Data source to fetch VM password from Key Vault
data "azurerm_key_vault" "existing" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

data "azurerm_key_vault_secret" "vm_password" {
  name         = var.vm_password_secret_name
  key_vault_id = data.azurerm_key_vault.existing.id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Public Subnet
resource "azurerm_subnet" "public" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Network Security Group and rules
resource "azurerm_network_security_group" "main" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Public IP for VM
resource "azurerm_public_ip" "main" {
  name                = "${var.vm_name}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = var.tags
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.vm_password.value
  
  # Disable password authentication and use password from Key Vault
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags

  # Provisioner to install Apache2 and create a simple webpage
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apache2",
      "sudo systemctl start apache2",
      "sudo systemctl enable apache2",
      "echo '<html><head><title>SP Terraform Project 2</title></head><body>' | sudo tee /var/www/html/index.html",
      "echo '<h1>Welcome to SP Terraform Project 2!</h1>' | sudo tee -a /var/www/html/index.html",
      "echo '<p>This VM was provisioned using Terraform with remote-exec provisioner.</p>' | sudo tee -a /var/www/html/index.html",
      "echo '<p>Apache2 web server is running successfully.</p>' | sudo tee -a /var/www/html/index.html",
      "echo '<p>VM Name: ${var.vm_name}</p>' | sudo tee -a /var/www/html/index.html",
      "echo '<p>Location: ${var.location}</p>' | sudo tee -a /var/www/html/index.html",
      "echo '<p>Date: $(date)</p>' | sudo tee -a /var/www/html/index.html",
      "echo '</body></html>' | sudo tee -a /var/www/html/index.html",
      "sudo systemctl reload apache2"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = data.azurerm_key_vault_secret.vm_password.value
      host     = azurerm_public_ip.main.ip_address
    }
  }
}

# Create VM Image from the provisioned VM
resource "azurerm_image" "main" {
  name                      = "${var.vm_name}-image"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  source_virtual_machine_id = azurerm_linux_virtual_machine.main.id

  tags = var.tags

  depends_on = [azurerm_linux_virtual_machine.main]
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "${var.scale_set_name}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Load Balancer for Scale Set
resource "azurerm_lb" "main" {
  name                = "${var.scale_set_name}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = var.tags
}

# Load Balancer Backend Pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.scale_set_name}-backend-pool"
}

# Load Balancer Health Probe
resource "azurerm_lb_probe" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "http-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

# Load Balancer Rule
resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "primary"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = var.scale_set_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.vm_size
  instances           = var.scale_set_capacity
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.vm_password.value
  
  # Use zones for high availability
  zones = var.availability_zones

  disable_password_authentication = false

  source_image_id = azurerm_image.main.id

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.public.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.main.id]
    }
  }

  tags = var.tags

  depends_on = [azurerm_image.main]
}

# Auto-scaling settings for the scale set
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "${var.scale_set_name}-autoscale"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "default"

    capacity {
      default = var.scale_set_capacity
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  tags = var.tags
}