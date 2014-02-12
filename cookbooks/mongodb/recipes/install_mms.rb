# CUSTOMIZE TO YOUR MMS account by filling in your API_KEY and SECRET_KEY here, mapped to your cloud environments
# You can find these in the “Settings” page of the MMS console.
# You will need to add a host to your MMS account to seed MMS.
# Add multiple groups, one per cloud environment

	API_KEYS = {
    "myiprodAU" => "9eb0e9d5fc8784f23732244fed5921ea",
    "myitestAU" => "add416b6d92aeb9b9336f7d2ee1207e1",
    }

  InstallDirectory = "/db/mms"
  MmsFileName = "mms-monitoring-agent"
  MmsZipFile = "#{MmsFileName}.zip"
  MmsZipUrl = "https://mms.mongodb.com/settings/#{MmsZipFile}"

if API_KEYS.has_key? @node[:environment][:name]
if !FileTest.directory?("#{InstallDirectory}/mms-agent")
  directory InstallDirectory do
    owner 'deploy'
    group 'deploy'
    mode  '0755'
    action :create
    recursive true
  end

  execute "Install Mongo Monitoring Service Dependencies" do
    command "sudo easy_install -U setuptools; sudo easy_install simplejson"    
  end

  execute "Install pymongo" do
    command "sudo easy_install pymongo"
  end

  # hack to fix distribute - setuptools breaks distribute on default EY machine
  execute "Fix Setup Tools" do
    command "cd #{InstallDirectory}; curl -O http://python-distribute.org/distribute_setup.py; sudo python distribute_setup.py; sudo rm distribute_setup.py"
  end

  execute "Fetch Mongo Monitoring Service zip file" do
    command "cd #{InstallDirectory}; wget #{MmsZipUrl}; unzip #{MmsZipFile}"
  end

  execute "Modify settings.py" do
     cwd "#{InstallDirectory}/mms-agent"
     command "sed -i 's/@DEFAULT_REQUIRE_VALID_SERVER_CERTIFICATES@/False/g' settings.py &&sed -i 's/@API_KEY@/#{API_KEYS[@node[:environment][:name]]}/g' settings.py && sed -i 's,@MMS_SERVER@,https://mms.mongodb.com,g' settings.py"


  end

  remote_file "#{InstallDirectory}/mms.sh" do
    owner "deploy"
    group "deploy"
    mode 0755
    source "mms.sh"
    backup false
    action :create
  end

  remote_file "/etc/monit.d/mms.monitrc" do
    owner "root"
    group "root"
    mode 0644
    source "mms.monitrc"
    backup false
    action :create
  end

  execute "Reload monit" do
    command "sudo monit reload && sudo monit"
  end

end
end
