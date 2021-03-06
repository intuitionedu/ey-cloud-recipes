#
# Cookbook Name:: mongodb
# Recipe:: default
#
# Save credentials on app_master
if ['app_master','app','solo','util'].include? @node[:instance_role]
  Chef::Log.info "creating app mongo.yml code"
  include_recipe "mongodb::app"
end

case node[:kernel][:machine]
when "i686"
  # Do nothing, you should never run MongoDB in a i686/i386 environment it will damage your data.
  # Chef::Log.info "MongoDB cannot be hold data in 32bit systems"

else
  if (@node[:instance_role] == 'util' && @node[:name].match(/mongodb_repl/))
    ey_cloud_report "mongodb" do
      message "configuring mongodb"
    end

    include_recipe "mongodb::install"
    include_recipe "mongodb::configure"
    include_recipe "mongodb::start"

    if @node[:mongo_replset]
      include_recipe "mongodb::replset"
    end
  end

  # Setup an arbiter on the db_master|solo as replica sets need another vote to properly failover.  If you have a Replica set > 3 nodes we don't set this up, you can tune this obviously.
  if (['app_master'].include?(@node[:instance_role]) &&  @node[:mongo_utility_instances].length == 2)
    Chef::Log.info "Setting up Mongo in app_master"
    include_recipe "mongodb::install"
    include_recipe "mongodb::configure"
    include_recipe "mongodb::start"
  end
end

#install mms on db_master or solo. This will need to change for db-less environments
if (@node[:instance_role] == 'util' && @node[:name].match(/#{@node[:mongo_replset]}_2$/))
  Chef::Log.info "Installing MMS on #{@node[:name]}"
  include_recipe "mongodb::install_mms"
end

#install mms on db_master or solo. This will need to change for db-less environments
if (@node[:instance_role] == 'util' && @node[:name].match(/#{@node[:mongo_replset]}_2$/))
  Chef::Log.info "Installing MMS backup on #{@node[:name]}"
  include_recipe "mongodb::backup"
end
