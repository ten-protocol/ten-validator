# Complete OVH + SGX + Terraform Guide

## Overview
OVH doesn't allow ordering servers via Terraform API, but we can **fully automate deployment** once ordered. This guide shows the most cost-effective way.

## Step 1: Find Cheapest SGX-Enabled OVH Server

### Option A: Advance-6 (Intel Xeon, SGX) - RECOMMENDED
- **SGX Support**: ✓ Yes (Intel 3rd Gen Xeon Ice Lake)
- **Estimated Cost**: ~$49-66/month (promotional)
- **Specs**: Unknown (need to check), but likely 8-12 vCores, 16-32GB RAM
- **Where**: https://www.ovhcloud.com/en/bare-metal/advance/

### Option B: Scale-i1 (Intel Xeon, SGX)
- **SGX Support**: ✓ Yes (Intel 4th Gen Xeon)
- **Cost**: ~$420/month
- **Specs**: 16 vCores, 32GB RAM, 2x960GB NVMe
- **Where**: https://www.ovhcloud.com/en/bare-metal/scale/

### Option C: Scale-i2 (Intel Xeon, SGX)
- **SGX Support**: ✓ Yes (Intel 4th Gen Xeon)
- **Cost**: ~$460+/month
- **Specs**: 24 vCores, 48GB RAM, 2x1.92TB NVMe

## Step 2: Verify SGX is Available (Check These)

1. **Go to**: https://www.ovhcloud.com/en/bare-metal/prices/
2. **Filter for**: "Advance-6" or "Scale-i1"
3. **Look for**: "Intel Xeon" processor (NOT AMD EPYC)
4. **Confirm**: Blog mentions "Intel SGX" support
5. **Add to cart** and note the service name (e.g., `ns12345.ip-1-2-3.eu`)

**⚠️ IMPORTANT**: Don't order AMD EPYC models - they have SEV, not SGX!

## Step 3: Order via OVH Control Panel

1. **Login**: https://www.ovhcloud.com/manager/
2. **Navigate**: Bare Metal > Dedicated Servers
3. **Select**: Cheapest Intel-based model with SGX
4. **OS**: Choose **Ubuntu 22.04 LTS**
5. **Network**: Enable SSH Access
6. **Complete**: Order and wait ~15-20 minutes for OS installation
7. **Note**: Your server name (shows as service name)

## Step 4: Get OVH API Credentials

```bash
# Visit: https://api.ovh.com/createToken/

# Fill in:
Token Validity: Unlimited
Requested permissions:
  - GET /dedicated/server/*
  - PUT /dedicated/server/*
  - GET /reverse/*
  - PUT /reverse/*

# Save:
- Application Key
- Application Secret
- Consumer Key
```

## Step 5: Prepare Terraform

```bash
# Navigate to terraform-ovh
cd terraform-ovh

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with YOUR values
nano terraform.tfvars
```

### terraform.tfvars Content:
```hcl
ovh_endpoint           = "ovh-eu"
ovh_application_key    = "YOUR_APP_KEY_HERE"
ovh_application_secret = "YOUR_APP_SECRET_HERE"
ovh_consumer_key       = "YOUR_CONSUMER_KEY_HERE"
ovh_service_name       = "ns12345.ip-1-2-3.eu"  # Your server name from step 3

username    = "tenuser"
domain_name = "ovh.net"

# Ten Validator ports
host_http_port      = 10000
host_websocket_port = 80
host_p2p_port       = 81
```

## Step 6: Deploy with Terraform

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy (SSH keys, DNS, Ansible provisioning)
terraform apply

# Wait 5-10 minutes for Ansible to complete
```

## Step 7: Verify SGX is Working

```bash
# Get your server IP
terraform output server_ip

# SSH into server
ssh -i ssh-key-ovh.pem tenuser@<SERVER_IP>

# Verify SGX is enabled
cpuid | grep SGX
# Should see: SGX: Software Guard Extensions supported

# Check Ten Validator is running
docker ps
docker logs ten-validator

# Test endpoints
curl http://localhost:10000/health
```

## Cost Breakdown

### Cheapest Option: Advance-6 (~$49-66/month)
```
Base Server:      $49-66/month
OS (Ubuntu):      FREE
Setup:            FREE or $0
Support:          Free basic
Total:            ~$49-66/month
```

### Mid Option: Scale-i1 (~$420/month)
```
Base Server:      $420/month
OS (Ubuntu):      FREE
Setup:            FREE
Support:          Free basic
Total:            ~$420/month
```

## Cost Optimization Tips

1. **Annual Commitment**: OVH offers ~20% discount for annual billing
   - Advance-6: ~$40/month with annual
   - Scale-i1: ~$336/month with annual

2. **Setup Fees**: Usually FREE for new customers

3. **Bandwidth**: Monitor egress - OVH charges for outbound traffic
   - Estimate: $0.015 per GB egress

4. **Promo Codes**: Check for OVH promotional codes

## Troubleshooting

### Server not ready after ordering
- OVH takes 15-30 minutes to install OS
- Check Control Panel for status
- Once "Ready" status shown, proceed with Terraform

### Terraform can't connect to server
```bash
# Wait longer - server may still be booting
sleep 60

# Check server is online
ping <SERVER_IP>

# Verify SSH is enabled in Control Panel
```

### Ansible provisioning fails
```bash
# Run manually for debugging
cd ../ansible

ansible-playbook \
  -i '<SERVER_IP>,' \
  -u tenuser \
  --private-key=../terraform-ovh/ssh-key-ovh.pem \
  -v \
  setup-validator-playbook.yaml
```

### SGX not detected
```bash
# Check BIOS - usually enabled by default on Scale/Advance
grep -i sgx /proc/cpuinfo

# If missing, enable in OVH Control Panel > Hardware > BIOS
```

## Full Timeline

| Step | Time |
|------|------|
| Order server | 5 min |
| Wait for OS install | 20 min |
| Generate OVH API token | 5 min |
| Configure Terraform | 5 min |
| Run Terraform | 10 min |
| Ansible deployment | 15 min |
| **Total** | **~60 minutes** |

## Next Steps After Deployment

1. **Verify validator is syncing**
   ```bash
   docker logs -f ten-validator
   ```

2. **Monitor performance**
   ```bash
   docker stats ten-validator
   ```

3. **Set up backup DNS** (optional)
   ```bash
   # Point backup DNS to server IP
   # In case primary DNS fails
   ```

4. **Enable OVH firewall** (optional)
   ```bash
   # Control Panel > Network > Firewall
   # Restrict to your IPs where possible
   ```

5. **Monitor costs**
   ```bash
   # OVH Control Panel > Billing
   # Set usage alerts
   ```

## Support

- **OVH Help**: https://help.ovhcloud.com/
- **OVH API**: https://api.ovh.com/console/
- **Terraform OVH Provider**: https://registry.terraform.io/providers/ovhhcloud/ovh/latest

---

**Summary**:
- Order cheapest Intel SGX server (likely Advance-6 at ~$50/month)
- Terraform handles all deployment automation
- Total setup time: ~60 minutes
- Full SGX support for Ten Validator
