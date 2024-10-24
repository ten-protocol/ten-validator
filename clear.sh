# script to clear terraform state

terraform destroy -auto-approve
rm -rf .terraform*
rm -rf terraform.tfstate*
