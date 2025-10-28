# Migrating from Azure to OVH

Guide for migrating your Ten Validator from Azure to OVH Bare Metal with SGX.

## Comparison: Azure vs OVH

| Aspect | Azure DC2ds_v3 | OVH Scale-i1 |
|--------|----------------|--------------|
| **SGX Support** | ✓ Yes (Confidential Compute) | ✓ Yes (3rd Gen Xeon) |
| **vCores** | 2 | 16 |
| **RAM** | 8 GB | 32 GB |
| **Storage** | 75 GB (Premium SSD) | 2x960 GB NVMe |
| **Monthly Cost** | ~$250 | ~$420 |
| **Cost/Core** | $125 | $26.25 |
| **Isolation** | VM hypervisor | Bare metal |
| **Setup Time** | ~3-5 min | ~20 min (OS install) |

## Pre-Migration Checklist

- [ ] Back up current validator state on Azure
- [ ] Document current configuration (ports, IPs, DNS records)
- [ ] Create OVH account and order Scale-i1 server
- [ ] Generate OVH API credentials
- [ ] Export validator data/state from Azure (if needed)

## Migration Steps

### 1. Prepare OVH Server

```bash
# Order Scale-i1 server via OVH Control Panel
# Wait for server to be ready

# Note server details:
SERVICE_NAME="ns12345.ip-1-2-3.eu"  # Your server name
SERVER_IP="1.2.3.4"                  # Your server IP
```

### 2. Export Data from Azure (if needed)

```bash
# SSH into Azure VM
az vm start --name ten_validatorVM --resource-group TEN_VALIDATOR
ssh -i ssh-key.pem tenuser@<azure-ip>

# Export validator data
docker exec ten-validator tar czf /tmp/validator-data.tar.gz /data/
docker cp ten_validator:/tmp/validator-data.tar.gz ./validator-data.tar.gz

# Download locally
scp -i ssh-key.pem tenuser@<azure-ip>:validator-data.tar.gz .
```

### 3. Deploy OVH Infrastructure

```bash
cd terraform-ovh

# Configure credentials
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your OVH credentials and server name

# Deploy
terraform init
terraform plan
terraform apply
```

### 4. Transfer Data to OVH (if needed)

```bash
# Upload data to OVH server
scp -i terraform-ovh/ssh-key-ovh.pem validator-data.tar.gz \
  tenuser@<ovh-ip>:/tmp/

# Extract on OVH server
ssh -i terraform-ovh/ssh-key-ovh.pem tenuser@<ovh-ip>
sudo tar xzf /tmp/validator-data.tar.gz -C /

# Update permissions
sudo chown -R dockremap:dockremap /data/
```

### 5. Update DNS Records

Update your DNS to point to the new OVH server:

```bash
# Get OVH server IP from Terraform output
terraform output server_ip

# Update DNS records:
# tenvalidator.example.com → <NEW_OVH_IP>

# Verify DNS propagation
nslookup tenvalidator.example.com
```

### 6. Update Firewall Rules

OVH Control Panel > Network > Firewall

Configure inbound rules:
- Port 22 (SSH) - Your IP only
- Port 80 (WebSocket)
- Port 81 (P2P)
- Port 10000 (HTTP API)

### 7. Verify Validator on OVH

```bash
ssh -i terraform-ovh/ssh-key-ovh.pem tenuser@<ovh-ip>

# Check SGX
cpuid | grep SGX
# Should see: "SGX: Software Guard Extensions supported"

# Check Docker
docker ps
docker logs ten-validator

# Test connectivity
curl http://localhost:10000/health
```

### 8. Switch Traffic to OVH

Once validated:
1. Redirect DNS to OVH IP
2. Monitor validator logs for errors
3. Decommission Azure VM (optional: keep for 24-48 hours as backup)

### 9. Clean up Azure Resources (Optional)

```bash
# Decommission Azure setup
cd terraform

# Stop and deallocate VM
terraform destroy

# Manually clean up in Azure Portal if needed
```

## Rollback Plan

If you encounter issues:

1. **Keep Azure VM running for 24-48 hours**
2. **Point DNS back to Azure IP** if needed
3. **Check logs for errors**:
   ```bash
   docker logs ten-validator -f
   ```

## Potential Issues and Solutions

### Issue: SGX Not Detected
```bash
# Verify server type
cat /proc/cpuinfo | grep "model name"
# Should show: Intel(R) Xeon(R) Platinum ... Processor

# Check BIOS settings
# OVH Scale-i1 has SGX enabled by default
```

### Issue: Network Connectivity
```bash
# Test from OVH server
ping 8.8.8.8
curl https://api.example.com

# Check network configuration
ip addr show
ip route show
```

### Issue: Docker Performance Drop
```bash
# OVH bare metal can have different disk performance
# Check disk performance:
fio --name=test --ioengine=libaio --iodepth=64 \
    --rw=write --bs=4k --direct=1 --size=1G

# Compare with Azure baseline
```

### Issue: High CPU Usage
```bash
# OVH has more cores (16 vs 2)
# Validator might behave differently
docker stats ten-validator
top -p $(docker inspect -f '{{.State.Pid}}' ten-validator)
```

## Performance Tuning on OVH

### Network Optimization
```bash
# Increase buffer sizes
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.wmem_max=134217728
sysctl -w net.core.rmem_default=134217728
sysctl -w net.core.wmem_default=134217728

# Save permanently
echo "net.core.rmem_max=134217728" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max=134217728" | sudo tee -a /etc/sysctl.conf
```

### Storage Optimization
```bash
# NVMe drives are fast, verify alignment
lsblk -o NAME,ALIGNMENT

# Use nvme0n1 for Docker data (if available)
docker inspect ten-validator | grep -i "data-root"
```

### CPU Pinning (Optional)
```bash
# Pin validator to specific CPUs for better performance
docker run --cpuset-cpus=0-3 \
  --memory=8g \
  ten-validator
```

## Cost Optimization Tips

1. **Annual Billing**: Save 20% with annual commitment
2. **Monitor bandwidth**: OVH charges for egress
3. **Right-size**: Scale-i1 may be oversized; monitor actual usage
4. **Use spot instances**: If available for bare metal

## Support

- **OVH Support**: https://help.ovhcloud.com/
- **Terraform Issues**: File issues in repository
- **Ten Validator Docs**: See main README.md

## Timeline

| Step | Duration |
|------|----------|
| OVH Server Provisioning | 15-20 min |
| OS Installation | 10-15 min |
| Terraform Deployment | 5-10 min |
| Ansible Playbooks | 10-15 min |
| Data Migration | Variable |
| Validation | 5-10 min |
| **Total** | **~1 hour** |

## Post-Migration Verification

```bash
# Monitor validator performance
while true; do
  echo "=== $(date) ==="
  docker stats --no-stream ten-validator
  docker logs --tail=5 ten-validator
  sleep 60
done
```

---

Need help? Check the [OVH README](./README.md) for more details.
