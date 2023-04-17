
#debug
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="d:\terraform.log"

# Terraform Docs
https://github.com/terraform-docs/terraform-docs
terraform-docs markdown table --output-file README.md --output-mode inject /path/to/module

terraform graph -type=plan | dot -Tpng -o graph.png  


# Terratest
$env:ARM_SUBSCRIPTION_ID="35d783e5-4f80-4982-860c-1ceab5884f7c" 

go mod init terratestmodules && go mod tidy
go test -v -timeout 60m


#inspec

#install inspec
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -project inspec

#prepare azure
az ad sp create-for-rbac -n "MyApp" --role Contributor


export AZURE_TENANT_ID="XXXXXXXXx"
export AZURE_CLIENT_ID="XXXXXXXXx"
export AZURE_CLIENT_SECRET="XXXXXXXXx"
export AZURE_SUBSCRIPTION_ID="XXXXXXXXx"


inspec init profile --platform azure azure-prof # create profile for azure with name azure-prof

inspec exec . -t azure:// --reporter cli junit:inspectestresults.xml # run tests and generate report
