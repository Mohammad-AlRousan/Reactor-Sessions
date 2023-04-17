

MyResourceGroup = 'Devios01-rg'
VmName = 'funtolearn02'


describe azure_virtual_machine(resource_group: MyResourceGroup, name: VmName) do
  it { should exist }
  it { should have_monitoring_agent_installed }
  it { should_not have_endpoint_protection_installed([]) }
  its('security_rules') { should_not be_empty }
  its('default_security_rules') { should_not be_empty }
  it { should_not allow_rdp_from_internet }
  it { should_not allow_ssh_from_internet }
  it { should allow(source_ip_range: '0.0.0.0', destination_port: '22', direction: 'inbound') }
  it { should allow_in(service_tag: 'Internet', port: %w{1433-1434 1521 4300-4350 5000-6000}) }
  it { should have_only_approved_extensions(['MicrosoftMonitoringAgent']) }
  its('type') { should eq 'Microsoft.Compute/virtualMachines' }
  its('installed_extensions_types') { should include('MicrosoftMonitoringAgent') }
  its('installed_extensions_names') { should include('LogAnalytics') }
end



###### SP Auth ##############################
export AZURE_TENANT_ID		 = ""
export AZURE_CLIENT_ID		 = ""
export AZURE_CLIENT_SECRET	 = ""
export AZURE_SUBSCRIPTION_ID = ""
##########################################