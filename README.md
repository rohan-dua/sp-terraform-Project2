# sp-terraform-Project2
1. creates a vm and basic resource required like resouce group, public subnet, public ip, vnet 
2. use provisioner remote-exec to install a simple webpage on apache2. 
3. Also ensure that password for the vm is fetched from azure security manager using data sources. 
4. Also i would like to convert this vm to an image and then use the image to create a scale set that provision one vm each in each zone of the region.


Execution Steps : 

- To create the keyvault, run the below command
    terraform apply -target=azurerm_resource_group.main -target=azurerm_key_vault.main -target=azurerm_key_vault_secret.vm_password
- Than to create rest resources run 
    terraform apply