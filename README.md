# Azure Splunk Lab - Infrastructure as Code

## Project Description
This repository contains the Infrastructure as Code (IaC) scripts required to deploy a distributed Splunk Enterprise environment on Microsoft Azure.

The project automates the provisioning of cloud resources using **Terraform** and manages the configuration of application services using **Ansible**. It demonstrates a real-world scenario of log aggregation, where a Universal Forwarder collects system logs and transmits them to a central Splunk Indexer.

## Architecture Overview

The infrastructure consists of two Azure Virtual Machines deployed within a secure Virtual Network (VNet):

* **Splunk Indexer (Server)**
    * **OS:** Ubuntu 22.04 LTS
    * **Size:** Standard_B2s
    * **Role:** Receives, parses, and indexes incoming log data.
    * **Networking:** Exposes port 8000 (Web UI) and 9997 (S2S Receiver).

* **Universal Forwarder (Client)**
    * **OS:** Ubuntu 22.04 LTS
    * **Size:** Standard_B1s
    * **Role:** Monitors `/var/log/syslog` and forwards data to the Indexer.

* **Security:** Network Security Groups (NSG) are configured to restrict administrative access (SSH/Web) to authorized IP addresses only.

## Prerequisites

* Azure CLI installed and authenticated (`az login`).
* Terraform (v1.0+).
* Ansible (v2.9+).
* SSH Key pair generated for Azure authentication.

## Deployment Instructions

### 1. Infrastructure Provisioning (Terraform)
Initialize the project and apply the configuration to create the Azure resources.

```bash
cd terraform
terraform init
terraform apply -auto-approve ```

Note: Upon completion, Terraform will output the public IP addresses for both the Indexer and the Forwarder.

### 2. Configuration Management (Ansible)
Update the inventory.ini file with the IP addresses obtained from the previous step.

Execute the playbook to install and configure the Splunk binaries. Note: To ensure security, the administrator password must be passed as an extra variable at runtime.

Bash

# Replace 'YourStrongPassword123!' with your actual password
ansible-playbook -i inventory.ini install_splunk.yml --extra-vars "splunk_password=YourStrongPassword123!"

### 3. Validation
Access the Splunk Web Interface at http://<INDEXER_IP>:8000.

Login with the username admin and the password defined in the step above.

Execute the following search query to verify log ingestion:

Extrait de code

index=main sourcetype=syslog
Technical Challenges & Resolution Log
During the implementation, the following technical issues were encountered and resolved:

Issue: Azure Public IP Allocation (SkuMismatch)

Error: Deployment failed with IPv4BasicSkuPublicIpCountLimitReached.

Root Cause: Azure has deprecated Basic SKU Public IPs for new subscriptions in the deployed region.

Resolution: Updated main.tf to explicitly define sku = "Standard" and allocation_method = "Static" for all public IP resources.

Issue: Forwarder Connectivity Failure

Error: The Universal Forwarder status was Configured but inactive.

Root Cause: An IP mismatch occurred during the configuration phase. The Forwarder was pointing to an outdated private IP address of the Indexer (10.0.1.4) instead of the actual assigned IP (10.0.1.5).

Resolution:

Verified service status on Indexer using ss -tulpn | grep 9997 (Confirmed LISTEN state).

Verified network reachability using telnet (Confirmed Connection Refused).

Corrected the forwarding destination via the Splunk CLI on the client machine.

Security Considerations
Secrets Management: No hardcoded credentials exist in the codebase. SSH keys and variable files (.tfvars) are excluded via .gitignore.

Network isolation: Inter-node communication (Splunk-to-Splunk) is restricted to the internal VNet subnet range.


