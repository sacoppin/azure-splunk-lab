# ☁️ Azure Splunk Lab: Automated Distributed Infrastructure

##  Project Overview
This project demonstrates a fully automated deployment of a **Distributed Splunk Architecture** on **Microsoft Azure**.
The goal was to simulate a real-world scenario where logs are collected from a client server (Universal Forwarder) and sent to a central indexing server (Splunk Enterprise), using **Infrastructure as Code (IaC)** principles.

**Key Technologies:**
* **Terraform:** Provisioning Azure resources (VMs, VNet, NSG, Public IPs).
* **Ansible:** Configuration Management (Installing Splunk, Configuring Forwarding).
* **Splunk Enterprise:** Central Log Management & Indexing.
* **Azure Cloud:** Infrastructure hosting.

---

##  Architecture
The infrastructure consists of two distinct Azure Virtual Machines communicating over a private network:

1.  **Splunk Indexer (Server):**
    * Instance: `Standard_B2s` (Ubuntu 22.04)
    * Role: Receives, parses, and indexes data.
    * Port `8000`: Web Interface.
    * Port `9997`: Splunk-to-Splunk (S2S) Listening.

2.  **Universal Forwarder (Client):**
    * Instance: `Standard_B1s` (Ubuntu 22.04)
    * Role: Monitors `/var/log/syslog` and forwards data to the Indexer.

---

##  Engineering Challenges & Troubleshooting
*This section highlights the technical hurdles encountered during the project and how they were resolved using a systematic troubleshooting approach.*

### 🔴 Challenge 1: Azure Public IP Allocation Error
* **Symptom:** Terraform failed with `IPv4BasicSkuPublicIpCountLimitReached`.
* **Diagnosis:** Azure has deprecated "Basic" SKU IPs for new subscriptions in certain regions.
* **Solution:** Refactored the `main.tf` code to explicitly request `Standard` SKU IPs with `Static` allocation method to comply with new Azure quotas.

### 🔴 Challenge 2: Forwarder Connectivity (S2S Failure)
* **Symptom:** The Universal Forwarder showed the Indexer as `Configured but inactive`. Logs were not arriving.
* **Troubleshooting Steps:**
    1.  **Service Check:** Verified Splunk was running on the Indexer using `systemctl status`.
    2.  **Port Check:** Used `sudo ss -tulpn | grep 9997` on the Indexer to confirm it was listening. **Result: OK.**
    3.  **Network Check:** Attempted `telnet <Indexer_IP> 9997` from the Forwarder. **Result: Connection Refused.**
* **Root Cause:** An IP Mismatch. The Forwarder was configured to point to `10.0.1.4`, but Azure had assigned `10.0.1.5` to the Indexer upon recreation.
* **Solution:** Updated the Forwarder configuration via CLI:
    ```bash
    ./splunk remove forward-server 10.0.1.4:9997
    ./splunk add forward-server 10.0.1.5:9997
    ```
    *Result: State changed to "Active forwards" immediately.*

---

##  How to Deploy

### Prerequisites
* Azure CLI (`az login`)
* Terraform installed
* Ansible installed

### 1. Provision Infrastructure
```bash
cd terraform
terraform init
terraform apply -auto-approve