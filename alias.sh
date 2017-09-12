alias pk_create='packer build --var-file=../../secrets/packer_vars.json --var-file=../../network.json packer.json'
alias tf_init='terraform init -var-file=../../secrets/terraform.tfvars'
alias tf_plan='terraform plan -var-file=../../secrets/terraform.tfvars'
alias tf_apply='terraform apply -var-file=../../secrets/terraform.tfvars'
alias tf_destroy='terraform destroy -var-file=../../secrets/terraform.tfvars'
