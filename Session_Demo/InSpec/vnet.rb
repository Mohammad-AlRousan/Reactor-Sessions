
resource_group = 'rg-vm01'
virtual_network = 'Devios01-rg-vnet'
address_space   = '10.0.0.0/16'
subnet1         = 'app-snet'


describe azurerm_virtual_network(resource_group: resource_group, name: virtual_network) do
    it { should exist }
    its('address_space') { should eq [address_space] }
    its('subnets') { should eq [subnet1] }
    its('location')  { should eq 'eastus' }
    its('dns_servers') { should eq ["10.10.0.6"] }
    
end



describe azure_network_security_group(resource_group: resource_group, name: 'ProdServers') do
    it { should exist }
    its('type') { should eq 'Microsoft.Network/networkSecurityGroups' }
    its('security_rules') { should_not be_empty }
    its('default_security_rules') { should_not be_empty }
    it { should_not allow_rdp_from_internet }
    it { should_not allow_ssh_from_internet }
    it { should allow(source_ip_range: '0.0.0.0', destination_port: '22', direction: 'inbound') }
    it { should allow_in(service_tag: 'Internet', port: %w{1433-1434 1521 4300-4350 5000-6000}) } 
  end
  
  
- task: Bash@3
            displayName: 'Run inspec tests'
            inputs:
              targetType: inline
              script: |
                export AZURE_SUBSCRIPTION_ID="$(AZURESUBSCRIPTIONID)"
                export AZURE_CLIENT_ID="$(AZURECLIENTID)"
                export AZURE_CLIENT_SECRET="$(AZURECLIENTSECRET)"
                export AZURE_TENANT_ID="$(AZURETENANTID)"
                inspec exec ./azure-inspec-tests/ -t azure:// --chef-license=accept --reporter cli junit:inspectestresults.xml
          - task: PublishTestResults@2
            displayName: Publish inspec test results
            condition: succeededOrFailed()
            inputs:
              testResultsFiles: '**/inspectestresults.xml'
              mergeTestResults: true
