# terraform_azure
Terraform Up and Running - Azure: going through Brikmans Terraform Up and Running and adjusting the AWS examples to Azure

Following is needed for a VM:
1/ provider
2/ VNet
3/ Subnet
4/ VM
5/ NSG
6/ NIC
7/ (public IP)
8/ VM
9/ NSG association to subnet / NIC

Add locals.tf (names, CIDRs and tags) and outputs.tf (e.g. public IP)

Test with:
ssh azureuser@$(terraform output -raw vm_public_ip)

!SSH is open for public IP! > Better to restrict to own IP 

