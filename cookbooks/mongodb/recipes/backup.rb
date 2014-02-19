# CUSTOMIZE TO YOUR MMS account by filling in your API_KEY and SECRET_KEY here, mapped to your cloud environments
# You can find these in the “Settings” page of the MMS console.
# You will need to add a host to your MMS account to seed MMS.
# Add multiple groups, one per cloud environment

	API_KEYS = {
    "myiprodAU" => "9eb0e9d5fc8784f23732244fed5921ea",
    "myitestAU" => "add416b6d92aeb9b9336f7d2ee1207e1",
    }

  InstallDirectory = "/db/backup"
  AgentFileName = "mongodb-mms-backup-agent-1.4.0.17-1.linux_x86_64"
  AgentZipFile = "#{AgentFileName}.tar.gz"
  AgentZipUrl = "https://mms.mongodb.com/settings/backupAgent/download/#{AgentZipFile}"

if API_KEYS.has_key? @node[:environment][:name]
if !FileTest.directory?("#{InstallDirectory}/mongodb-mms-backup-agent-1.4.0.17-1.linux_x86_64")
  directory InstallDirectory do
    owner 'deploy'
    group 'deploy'
    mode  '0755'
    action :create
    recursive true
  end

  execute "Fetch Mongo Monitoring Service zip file" do
    command "cd #{InstallDirectory}; wget #{AgentZipUrl}; tar -zxvf #{AgentZipFile}"
  end

  execute "Modify local.config" do
     cwd "#{InstallDirectory}/mongodb-mms-backup-agent-1.4.0.17-1.linux_x86_64"
     command "sed -i 's/apiKey=/apiKey=#{API_KEYS[@node[:environment][:name]]}/g' local.config"
  end

  remote_file "#{InstallDirectory}/mongodb-mms-backup-agent-1.4.0.17-1.linux_x86_64/mms_backup.sh" do
    owner "deploy"
    group "deploy"
    mode 0755
    source "mms_backup.sh"
    backup false
    action :create
  end

  remote_file "/etc/monit.d/mms_backup.monitrc" do
    owner "root"
    group "root"
    mode 0644
    source "mms_backup.monitrc"
    backup false
    action :create
  end

  execute "Reload monit" do
    command "sudo monit reload && sudo monit start mms_backup"
  end

end
end
