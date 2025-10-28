# Ten Validator on OVH Bare Metal with Intel SGX

Terraform configuration for deploying the Ten Validator on OVH's Intel Xeon bare metal servers with Intel SGX support. This provides hardware-level security for the validator enclave at a competitive cost.

## Why OVH Bare Metal with SGX?

| Feature | OVH Advance-6 | OVH Scale-i1 | Azure DC2ds_v3 |
|---------|---|---|---|
| **Intel SGX** | ✓ Yes | ✓ Yes | ✓ Yes |
| **CPUs** | ~8-12 | 16 | 2 |
| **RAM** | ~16-32GB | 32 GB | 8 GB |
| **Cost/Month** | ~$49-66 | ~$420 | ~$200-300 |
| **Cost/Core** | ~$6-8 | $26.25 | $100-150 |
| **Automation** | ✓ Terraform | ✓ Terraform | ✓ Terraform |

**Recommended:** Advance-6 offers best price-to-performance with full Intel SGX support and Terraform automation.

## How It Works

This is a **hybrid approach**:
1. **Manual Step**: Order bare metal server via OVH Control Panel (~5 minutes)
2. **Automated**: Terraform handles deployment and configuration
3. **Ansible**: Automatically deploys Docker and Ten Validator

For detailed ordering guide, see [OVH_ORDERING_GUIDE.md](./OVH_ORDERING_GUIDE.md)

## Prerequisites

1. **OVH Account** with an ordered Bare Metal Server (Advance-6, Scale-i1, or Scale-i2)
   - Must have **Intel processor with SGX** (not AMD EPYC)
   - Must be running **Ubuntu 22.04 LTS**
   - Must have **SSH enabled**
   - Available regions: EU (Paris, Strasbourg, Gravelines, Roubaix), US (Beauharnois)
   - See [OVH_ORDERING_GUIDE.md](./OVH_ORDERING_GUIDE.md) for step-by-step ordering instructions

2. **OVH API Credentials**
   - Visit: https://api.ovh.com/createToken/
   - Request permissions for:
     - `GET /dedicated/server/*`
     - `PUT /dedicated/server/*`
   - Save: Application Key, Application Secret, Consumer Key

3. **Terraform** >= 0.12
   ```bash
   terraform --version
   ```

4. **Ansible** >= 2.9 (for Docker deployment)
   ```bash
   ansible --version
   ```

5. **SSH Access** to OVH server (enabled in Control Panel)

## Quick Start (5 Minutes After Server is Running)

```bash
cd terraform-ovh

# 1. Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
# Enter your OVH API credentials and server name

# 2. Deploy
terraform init
terraform plan
terraform apply

# 3. Wait for Ansible to complete (~10-15 minutes)
# 4. Verify validator is running
ssh -i ssh-key-ovh.pem tenuser@<SERVER_IP>
docker logs ten-validator
```

## Step-by-Step Setup Instructions

### Step 1: Order and Prepare OVH Server

**See [OVH_ORDERING_GUIDE.md](./OVH_ORDERING_GUIDE.md) for detailed ordering instructions**

Quick summary:
1. Log in to [OVH Control Panel](https://www.ovh.com/manager/dedicated)
2. Order cheapest **Intel SGX server** (Advance-6 recommended at ~$49-66/month)
3. Choose **Ubuntu 22.04 LTS** as OS
4. Enable **SSH Access**
5. Wait for OS installation (~15-20 minutes)
6. Note your server name (e.g., `ns12345.ip-1-2-3.eu`)

### Step 2: Generate OVH API Credentials

1. Go to https://api.ovh.com/createToken/
2. Set Token Validity: **Unlimited**
3. Request permissions:
   ```
   GET /dedicated/server/*
   PUT /dedicated/server/*
   GET /reverse/*
   PUT /reverse/*
   ```
4. Click **Create Token** and save the credentials:
   - Application Key
   - Application Secret
   - Consumer Key

### Step 3: Configure Terraform

1. Copy the example configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your OVH credentials and server details:
   ```hcl
   ovh_endpoint           = "ovh-eu"
   ovh_application_key    = "YOUR_APP_KEY_HERE"
   ovh_application_secret = "YOUR_APP_SECRET_HERE"
   ovh_consumer_key       = "YOUR_CONSUMER_KEY_HERE"
   ovh_service_name       = "ns12345.ip-1-2-3.eu"  # Your server name
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

### Step 4: Review and Deploy

1. Review the deployment plan:
   ```bash
   terraform plan
   ```

2. Apply the configuration:
   ```bash
   terraform apply
   ```

3. Terraform will:
   - Generate SSH keys locally
   - Configure reverse DNS
   - Wait for server connectivity
   - Run Ansible playbooks to install Docker & Ten Validator
   - Output SSH connection details

### Step 5: Verify Deployment

After Terraform completes, verify the installation:

```bash
# Connect to server
ssh -i terraform-ovh/ssh-key-ovh.pem tenuser@<SERVER_IP>

# Check SGX is enabled
cpuid | grep SGX

# Verify Docker installation
docker --version

# Check Ten Validator container
docker ps
docker logs ten-validator

# Verify ports are open
netstat -tlnp | grep -E ':(80|81|10000)'
```

## Customization

### Change Validator Ports

Edit `terraform.tfvars`:
```hcl
host_http_port      = 10000  # Web API port
host_websocket_port = 80     # WebSocket port
host_p2p_port       = 81     # P2P port
```

### Change Username

Edit `terraform.tfvars`:
```hcl
username = "customuser"
```

### Modify Ansible Playbooks

Edit the Ansible playbook that Terraform calls:
```bash
# Update the playbook referenced in main.tf
../ansible/setup-validator-playbook.yaml
```

## Network Security

The deployment includes SSH key-based authentication and opens the following ports:

| Port | Service | Protocol |
|------|---------|----------|
| 22 | SSH | TCP |
| 80 | WebSocket | TCP |
| 81 | P2P | TCP |
| 10000 | HTTP API | TCP |

**Recommended:** Use OVH Control Panel to restrict access by IP if possible.

## Troubleshooting

### Connection Timeout
```bash
# Wait for server to fully boot (may take 5-10 minutes)
# Check server status in OVH Control Panel
# Verify SSH is enabled for the server
```

### Ansible Playbook Errors
```bash
# Run Ansible manually to debug
ansible-playbook -i '<SERVER_IP>,' \
  -u tenuser \
  --private-key=terraform-ovh/ssh-key-ovh.pem \
  -v \
  ../ansible/setup-validator-playbook.yaml
```

### SGX Not Detected
```bash
# Check in server
grep -i sgx /proc/cpuinfo
cpuid | grep SGX

# If not present, verify:
# 1. Server is Scale-i1 or newer (not older generations)
# 2. SGX is enabled in BIOS (usually default)
# 3. OS supports SGX (Ubuntu 22.04 LTS does)
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

This will:
- Remove SSH keys from local filesystem
- Remove reverse DNS entry
- **NOTE:** It does NOT delete the OVH bare metal server itself (you manage that via OVH Control Panel)

## Cost Estimation

### OVH Scale-i1 Pricing (EU region)
- **Monthly**: ~$420 / month
- **Hourly**: ~$0.58 / hour
- **Hourly Savings Plan**: ~$0.48 / hour (20% discount)

### Total Cost Comparison (Monthly)

| Component | OVH Scale-i1 | Azure DC2ds_v3 |
|-----------|--------------|----------------|
| Compute | $420 | $200-300 |
| Storage | Included | $20-50 |
| Network | $0 | $0-10 |
| **Total** | **$420** | **$220-360** |

**Note:** OVH provides significantly more compute resources. Cost per core is much lower.

## Support and Documentation

- **OVH API Docs**: https://api.ovh.com/console/
- **Terraform OVH Provider**: https://registry.terraform.io/providers/ovhhcloud/ovh/latest/docs
- **OVH Bare Metal Support**: https://help.ovhcloud.com/

## Advanced: Manual Ansible Playbook Execution

If Terraform provisioning fails, run Ansible manually:

```bash
cd ../ansible

# Run validator setup
ansible-playbook -i '<SERVER_IP>,' \
  -u tenuser \
  --private-key=../terraform-ovh/ssh-key-ovh.pem \
  setup-validator-playbook.yaml

# Check playbook syntax
ansible-playbook --syntax-check setup-validator-playbook.yaml

# Run with verbose output
ansible-playbook -vvv \
  -i '<SERVER_IP>,' \
  -u tenuser \
  --private-key=../terraform-ovh/ssh-key-ovh.pem \
  setup-validator-playbook.yaml
```

## Tips for Minimum Cost

1. **Use Savings Plan**: OVH offers 20% discount with annual commitment
2. **Right-size Resources**: Scale-i1 is the smallest SGX server; consider if you need more
3. **Monitor Bandwidth**: OVH charges for egress bandwidth; validate your network needs
4. **Use Spot Instances**: If available, OVH spot bare metal could offer further savings

## Next Steps

1. Deploy the validator
2. Configure firewall rules via OVH Control Panel
3. Set up monitoring (CloudWatch, Datadog, Prometheus)
4. Configure automated backups
5. Set up alerting for validator health

---

For more information, see the main [Ten Validator documentation](../README.md)
