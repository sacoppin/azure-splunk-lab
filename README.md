# Azure Splunk Lab - Infrastructure as Code

## Project Description
This repository contains the Infrastructure as Code (IaC) scripts required to deploy a distributed Splunk Enterprise environment on Microsoft Azure.

The project automates the provisioning of cloud resources using **Terraform** and manages the configuration of application services using **Ansible**. It demonstrates a real-world scenario of log aggregation, where a Universal Forwarder collects system logs and transmits them to a central Splunk Indexer.

---

## Architecture Overview
The infrastructure consists of two Azure Virtual Machines deployed within a secure Virtual Network (VNet):
   Component               | Details                                                                                     |
 |-------------------------|---------------------------------------------------------------------------------------------|
 | **Splunk Indexer**      | **OS:** Ubuntu 22.04 LTS<br>**Size:** Standard_B2s (optimized for memory)<br>**Role:** Receives, parses, and indexes incoming log data.<br>**Networking:** Exposes port 8000 (Web UI) and 9997 (S2S Receiver). |
 | **Universal Forwarder** | **OS:** Ubuntu 22.04 LTS<br>**Size:** Standard_B1s<br>**Role:** Monitors `/var/log/syslog` and forwards data to the Indexer. |
 | **Security**            | Network Security Groups (NSG) are configured to restrict administrative access (SSH/Web) to authorized IP addresses only. |

---

## Prerequisites
- Azure CLI installed and authenticated (`az login`).
- Terraform (v1.0+).
- Ansible (v2.9+).
- SSH Key pair generated for Azure authentication.

---

## Deployment Instructions

### 1. Infrastructure Provisioning (Terraform)
Initialize the project and apply the configuration to create the Azure resources.

```bash
cd terraform
terraform init
terraform apply -auto-approve

```

Note: Upon completion, Terraform will output the public IP addresses for both the Indexer and the Forwarder.

### 2. Configuration Management (Ansible)
First, update the inventory.ini file with the IP addresses obtained from the previous step.
Then, execute the playbook to install and configure the Splunk binaries.
Note: To ensure security, the administrator password must be passed as an extra variable at runtime.
bash
Copy

#### Replace 'YourStrongPassword123!' with your actual password
ansible-playbook -i inventory.ini install_splunk.yml --extra-vars "splunk_password=YourStrongPassword123!"


### 3. Validation

Access the Splunk Web Interface at http://<INDEXER_IP>:8000.
Login with the username admin and the password defined in the step above.
Execute the following search query to verify log ingestion:
Copy

index=main sourcetype=syslog

