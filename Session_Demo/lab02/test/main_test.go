package main

// Import key modules.
import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

var (
	globalBackendConf = make(map[string]interface{})
	globalEnvVars     = make(map[string]string)
	uniquePostfix     = strings.ToLower(random.UniqueId())
	prefix            = "vnet"
	separator         = "-"
)

func TestTerraform_azure_virtualNetwork(t *testing.T) {
	t.Parallel()
	setTerraformVariables()

	expectedLocation := "northeurope"
	expectedAddressSpace := "10.10.0.0/16"

	// Use Terratest to deploy the infrastructure
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../lab02",
		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"resource_group_name": resource_group_name,
			"location":            expectedLocation,
			"prefix":              prefix,
			"postfix":             uniquePostfix,
			"address_space":       expectedAddressSpace,
		},
		// globalvariables for user account
		EnvVars: globalEnvVars,
		// Backend values to set when initialziing Terraform
		BackendConfig: globalBackendConf,
		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
		// Reconfigure is required if module deployment and go test pipelines are running in one stage
		Reconfigure: true,
	})
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)
	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)
	expectedResourceName := terraform.Output(t, terraformOptions, "resource_name")
}
