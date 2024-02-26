# HybridNetworkSim

<h1>Deployed a Hybrid Network Simulation using Terraform.</h1>



<h2>Description</h2>

-  Topology: A  virtual network with resources that allow connectivity to two simulated on-premises networks.
-  Resources deployed:  4 Virtual Machines (4NICs), Bastion Host (Standard | 1 PIP), 2 Azure VPN Gateway (Basic | 2 PIPs), 
   5 PIPs  in total (Standard | Regional), Azure SQL Server  and Database, 2 Load Balancers (Standard | 2 PIPs | 2 NICs),
   Private EndPoint and Private Link (Load balancer | 1PIP), Local Network Gateway, DNS Zone and DNS records.
-  Vnet Peerings - Azure Vnet to Simulated onprem vnet; simulated onprem vnet to azure vnet.
-  Azure Vnet - Contains: AzureBastionSubnet, GatewaySubnet(vpngateway), WebApp Subnet, Database Subnet, Admin Subnet. 
-  Simulated On-prem Vnet - Contains: GatewaySubnet(vpngateway).
-  Onprem Network - Contains: Local Network Gateway, Vnet Gateway Connection to Azure vnet VPN Gateway (IPsec).
-  NSGs- WebApp NSG(Security Rule: Allow HTTPs), Subnets NSG (Security Rules: Allow Inbound RDP, Allow inbound ssh, Deny All Inbound, Allow Outbound to Subnets). NSG association was 
   performed with each subnet in VNet
-  Virtual Machines - Standard B1ls | Linux VM. 2 Virtual Machines were deployed into the WebApp Subnet.
-  Load Balancers - LB was deployed with the 2 virtual machines for the webapp as the backend pool.
-  Private Endpoint - Deployed in Database Subnet. Private service connection was made to the previously deployed SQL Server.

-  main.tf template to define resources. 

-  Azure CLI command:
 terraform init
 terraform plan
 terraform apply 
 <br />


<h2>Languages used</h2>

- <b>Terraform</b> 
- <b>Azure CLI</b>


<h2>Environments Used </h2>

- <b>Vs Code</b>
- <b>Azure Portal</b> 

<h2>Network Topoloy </h2>

<img src="https://i.imgur.com/HIueCqh" height="80%" width="80%" alt="Network Topology"/>
<br />



