# azure-vmss-autoscale-demo
### 1. Creation of a local VM (Oracle Linux 7.8 using VirtualBox)
- Download and install the latest Oracle VM VirtualBox from the official Oracle website (https://www.virtualbox.org/).
- Download the Oracle Linux 7.8 Server ISO (full DVD image) directly from the official Oracle Linux yum server:  
  https://yum.oracle.com/ISOS/OracleLinux/OL7/u8/x86_64/OracleLinux-R7-U8-Server-x86_64-dvd.iso (or the boot ISO if preferred).
- Create a new VM in VirtualBox:
  - Name: `OL78-LocalVM`
  - Type: Linux → Oracle Linux (64-bit)
  - Memory: 4096 MB (or more for testing)
  - CPU: 2 cores
  - Hard disk: Create a virtual hard disk (VDI, dynamically allocated, 20 GB minimum)
  - Storage: Attach the downloaded ISO to the optical drive
  - Network: Bridged Adapter (for easy Azure CLI access)
  - Enable EFI if needed (but BIOS is fine for OL 7.8)
- Start the VM and perform a standard minimal server installation:
  - Select “Minimal Install”
  - Set hostname: `local-vm`
  - Configure networking (enable DHCP)
  - Set root password and create a sudo user (e.g., `admin`)
  - Finish installation and reboot
- Post-install (inside the VM):
  ```
  sudo yum update -y
  sudo yum install -y epel-release
  sudo yum install -y sysstat bc python3 curl
  sudo systemctl enable --now sshd
  ```
- Install VirtualBox Guest Additions for better performance (optional but recommended).

### 2. Implementation of resource monitoring (custom Bash script + sysstat)
- Install monitoring tools:
  ```
  sudo yum install -y sysstat
  sudo systemctl enable --now sysstat
  ```
- Create the monitoring script `/home/admin/monitor_resources.sh` (full code provided in the Source Code section below).
  - The script uses `mpstat` to check average CPU usage every 30 seconds.
  - If CPU > 75% for 5 consecutive checks (~2.5 minutes), it triggers the Azure scaling script.
  - It also logs RAM usage (via `free`) for completeness.
- Make it executable and run via cron (or as a systemd service for production):
  ```
  chmod +x /home/admin/monitor_resources.sh
  crontab -e
  ```
  Add: `@reboot /home/admin/monitor_resources.sh >> /var/log/resource-monitor.log 2>&1`

### 3. Configuration of cloud auto-scaling policies and resource migration (Azure)
- On the local VM, install Azure CLI:
  ```
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1" > /etc/yum.repos.d/azure-cli.repo'
  sudo yum install -y azure-cli
  ```
- Authenticate (recommended: create a Service Principal for automation, or use `az login` interactively for demo):
  ```
  az login
  ```
- In Azure Portal (or via CLI), create the following once:
  - Resource Group: `hybrid-scale-rg`
  - VM Scale Set (`az vmss create`):
    - Image: `OracleLinux:Oracle-Linux:7.9:latest` (closest supported; 7.8 is legacy) or Ubuntu Server 20.04 LTS for easier app deployment
    - Instance count: min=1, max=5
    - Instance size: Standard_D2s_v3
    - Use a custom script extension or cloud-init to install your sample app automatically on new instances
  - Auto-scale setting on the VMSS (via Azure Portal → VM Scale Set → Scaling):
    - Metric: CPU Percentage
    - Scale out when CPU > 70% (for 5 minutes)
    - Scale in when CPU < 30%
    - This provides the cloud-native auto-scaling policy.
- Create the deployment/trigger script `/home/admin/deploy_to_azure.sh` (full code in Source Code section).
  - When triggered by the monitor, it scales out the VMSS by 1–2 instances (resource “migration” via load-balanced cloud instances).
  - The sample app is deployed via VMSS custom-script extension (stateless web app example).

### 4. Deployment of a sample application to demonstrate the process
- Sample app: A simple Python Flask web server (CPU-stressable).
  - On local VM: Install and run the app (see code below).
  - On Azure VMSS: The same app is installed automatically via custom script extension when instances are created/scaled.
- To demonstrate:
  - Start the app on local VM.
  - Use `stress-ng --cpu 2 --timeout 600s` (install `stress-ng`) to simulate high load.
  - Watch the monitoring script detect >75% CPU and automatically scale out the Azure VMSS.
  - Traffic can be manually redirected (or use Azure Load Balancer in a real setup) to show the app now runs on cloud.

**Architecture Design**  
 
<img width="880" height="1381" alt="image" src="https://github.com/user-attachments/assets/5432db23-fda1-41be-97d5-33c75ed412e8" />


Install dependencies on local VM: `sudo yum install -y python3-pip; pip3 install flask`.  
Run with: `python3 sample_app.py`.  
For Azure VMSS, add the install steps + `nohup python3 sample_app.py &` in the custom script extension.


 5. Link to Source Code Repo
https://github.com/udaymote2006/azure-vmss-autoscale-demo
