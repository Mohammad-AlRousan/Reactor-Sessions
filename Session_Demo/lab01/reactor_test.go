package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestResourceGroup(t *testing.T) {
	subscriptionID := "35d783e5-4f80-4982-860c-1ceab5884f7c"
	resource_group_location := "westeurope"

	// Use Terratest to deploy the infrastructure
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "./",
		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
		// Reconfigure is required if module deployment and go test pipelines are running in one stage
		Reconfigure: true,
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)
	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	resourceGroupName := terraform.Output(t, terraformOptions, "rg_name")
	resourceGroup := azure.GetAResourceGroup(t, resourceGroupName, subscriptionID)

	assert.Equal(t, resourceGroupName, *resourceGroup.Name)
	assert.Equal(t, resource_group_location, *resourceGroup.Location)
}
