# Ten Validator on OVH Bare Metal with Intel SGX

Terraform configuration for deploying the Ten Validator on OVH's Intel Xeon bare metal servers with Intel SGX support. This provides hardware-level security for the validator enclave at a competitive cost.

## Why OVH Bare Metal with SGX?

| Feature | **OVH Rise-6** ✅ RECOMMENDED | OVH Scale-i1 | Azure DC2ds_v3 |
|---------|---|---|---|
| **Intel SGX** | ✓ Yes | ✓ Yes | ✓ Yes |
| **CPUs** | **24 cores** | 16 cores | 2 cores |
| **Threads** | **48 threads** | - | - |
| **RAM** | 128GB-1TB | 32 GB | 8 GB |
| **Storage** | 2x960GB-12TB | 2x960GB | 75GB |
| **Cost/Month** | **$233** | ~$420+ | ~$200-300 |
| **Cost/Core** | **$9.70** | $26.25 | $100-150 |
| **Headroom** | 59% | 37.5% | - |
| **Automation** | ✓ Terraform | ✓ Terraform | ✓ Terraform |
| **SGX Type** | Intel 3rd Gen Xeon (Ice Lake) | Intel 4th Gen Xeon | Intel CC |
| **Available** | ✅ On pricing page | ✅ On pricing page | - |

**WINNER:** Rise-6 is **45% cheaper** than Scale-i1 with **50% more cores** and massive headroom!

## How It Works

This is a **hybrid approach**:
1. **Manual Step**: Order bare metal server via OVH Control Panel (~5 minutes)
2. **Automated**: Terraform handles deployment and configuration
3. **Ansible**: Automatically deploys Docker and Ten Validator

For detailed ordering guide, see [OVH_ORDERING_GUIDE.md](./OVH_ORDERING_GUIDE.md)

## Prerequisites

1. **OVH Account** with an ordered Bare Metal Server WITH Intel SGX
   - **RECOMMENDED**: Rise-6 (24 cores, 128GB-1TB RAM, **$233/month**, Intel SGX) ✅ BEST VALUE
   - **ALTERNATIVE**: Scale-i1 (16 cores, 32GB RAM, ~$420+/month, Intel SGX)
   - **NOT RECOMMENDED**: Scale-i2 (24 cores, 48GB RAM, ~$460+/month - more expensive than Rise-6!)
   - Must have **Intel Xeon processor with SGX** (not AMD EPYC)
   - Must be running **Ubuntu 22.04 LTS**
   - Must have **SSH enabled**
   - Filter at: https://www.ovhcloud.com/en/bare-metal/prices/?display=list&use_cases=confidential-computing
   - Available regions: Asia Pacific, North America, Europe
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

## Resource Requirements (Based on Actual Kubernetes YAML)

From `/ten-apps/charts/ten-node/values.yaml` - actual production configuration:

### 1. Enclave Pod (StatefulSet with 2 containers)

**EdgelessDB Container:**
```yaml
resources:
  limits:
    cpu: 4000m (4 cores)
    memory: 8Gi
    sgx.intel.com/epc: 6Gi
    sgx.intel.com/enclave: 10
    sgx.intel.com/provision: 10
  requests:
    cpu: 2000m (2 cores)
    memory: 6Gi
    sgx.intel.com/epc: 6Gi
```

**TEN Enclave Container:**
```yaml
resources:
  limits:
    cpu: 2000m (2 cores)
    memory: 4Gi
  requests:
    cpu: 1000m (1 core)
    memory: 4Gi
```

**Enclave Pod Totals:**
- **Limits**: 6 cores, 12Gi RAM, 6Gi EPC
- **Requests**: 3 cores, 10Gi RAM, 6Gi EPC

### 2. Host Pod (Deployment)

```yaml
resources:
  limits:
    cpu: 500m (0.5 cores)
    memory: 1Gi
  requests:
    cpu: 200m (0.2 cores)
    memory: 1Gi
```

### 3. System Total Requirements

| Component | Requests | Limits | Notes |
|-----------|----------|--------|-------|
| **Enclave Pod** | 3 cores | 6 cores | EdgelessDB + TEN Enclave |
| **Host Pod** | 0.2 cores | 0.5 cores | Host OS node |
| **OS/Kernel** | ~1-2 cores | ~2-3 cores | System overhead |
| **Monitoring/Logging** | ~0.5-1 core | ~1-2 cores | Optional but recommended |
| **Headroom (20%)** | ~1-2 cores | ~2-4 cores | For stability, no throttling |
| **TOTAL SAFE MINIMUM** | **6-7 cores** | **11-15 cores** | - |

### Why 8 Cores is Insufficient

❌ **Intel Xeon-E 2388G (8 cores) Problems:**
- Enclave limits alone = 6 cores (75% of total!)
- Only 2 cores left for: Host + OS + Kernel + Monitoring
- **Result**: Constant CPU throttling, slow performance, unstable under load

### Why Rise-6 (24 cores) is Optimal ✅ RECOMMENDED

✅ **OVH Rise-6 (24 cores) Resource Allocation:**

```
Available: 24 physical cores

Allocation:
├─ Enclave Pod limits:     6 cores  (25%)
├─ Host Pod limits:        0.5 cores (2%)
├─ Kernel/OS overhead:     2 cores  (8%)
├─ Monitoring/Logging:     1.5 cores (6%)
└─ Headroom/Buffer:        14 cores (59%) ✅✅✅ MASSIVE ROOM!
```

**Rise-6 Final Specs:**

| Resource | Kubernetes Requires | Rise-6 Provides | Utilization | Status |
|----------|-------------------|-------------------|-------------|--------|
| **vCPU** | 11-15 cores (safe) | 24 cores | 45-62% safe | ✅✅ Excellent |
| **RAM** | 11Gi (requests) | 128GB-1TB | <1% | ✅✅ Outstanding |
| **EPC** | 6Gi | 128+ GB | <5% | ✅ More than enough |
| **SGX** | Required | Intel 3rd Gen Xeon (Ice Lake) | Full support | ✅ Full support |
| **Cost** | Budget-conscious | $233/month | BEST VALUE | ✅ 45% cheaper |

**Key Advantages:**
- **59% headroom** - massive buffer for stability and scaling
- 24 cores = 12x overallocation prevents ANY throttling
- Kernel/system has abundant capacity
- Monitoring has zero impact on validator
- Easy room to add multiple validators or other workloads
- **$233/month** is 45% cheaper than Scale-i1
- RAM flexibility (128GB-1TB) for future scaling

**vs Scale-i1:**
- Rise-6: 24 cores @ $233/month = **$9.70/core**
- Scale-i1: 16 cores @ $420+/month = **$26.25/core**
- **Rise-6 saves $187+/month while providing 50% more cores!**

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
2. Go to: https://www.ovhcloud.com/en/bare-metal/prices/?display=list&use_cases=confidential-computing
3. Order **Rise-6** (24 cores, 128GB-1TB RAM, Intel SGX) - **$233/month** ✅ BEST VALUE
   - Intel Xeon Gold 6312U (3rd Gen, Ice Lake)
   - 24 cores / 48 threads
   - Recommended starting RAM: 128GB (can order up to 1TB)
   - **Why Rise-6?** 24 cores for $233/month beats Scale-i1 (16 cores for $420+/month)
4. Choose **Ubuntu 22.04 LTS** as OS
5. Enable **SSH Access**
6. Wait for OS installation (~15-20 minutes)
7. Note your server name (e.g., `rise6-xxx.ip-1-2-3.eu`)

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

### OVH Rise-6 Pricing (Intel SGX with 24 vCores) ✅ RECOMMENDED

**Base Configuration (128GB RAM):**
- **Monthly**: $233/month ← BEST VALUE
- **Per Core**: $9.70/core
- **Storage**: 2x960GB SSD NVMe (standard)
- **Bandwidth**: 1-3 Gbps public, 1-2 Gbps private

**Optional Upgrades:**
- Upgrade to 256GB RAM: Small additional cost
- Upgrade to 512GB RAM: Modest additional cost
- Upgrade to 1TB RAM: Larger but still reasonable cost

### Comparison to Other Options

| Feature | **OVH Rise-6** ✅ | OVH Scale-i1 | Azure DC2ds_v3 |
|---------|---|---|---|
| **vCores** | 24 | 16 | 2 |
| **Base RAM** | 128GB | 32GB | 8GB |
| **Storage** | 2x960GB | 2x960GB | 75GB |
| **Monthly Cost** | **$233** | $420+ | $200-300 |
| **Cost/Core** | **$9.70** | $26.25 | $100-150 |
| **Annual Savings vs Scale-i1** | **+$2,244/year** | - | - |
| **Annual Savings vs Azure** | **+$12+/year** | - | - |

### Real-World Annual Cost

```
Rise-6:      $233 x 12 = $2,796/year
Scale-i1:    $420 x 12 = $5,040/year
Azure:       $250 x 12 = $3,000/year

Rise-6 Advantage: SAVE $2,244/year vs Scale-i1! 💰
```

**Why Rise-6 wins on cost:**
1. Lowest price ($233/month)
2. Most cores per dollar ($9.70/core)
3. Largest RAM pool (start at 128GB, scale to 1TB)
4. Full Intel SGX support included

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
