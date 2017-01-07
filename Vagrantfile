# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "dbcdb" , primary: true do |dbcdb|

    dbcdb.vm.box = "centos-6.7-x86_64"
    dbcdb.vm.box_url = "https://dl.dropboxusercontent.com/s/m2pr3ln3iim1lzo/centos-6.7-x86_64.box"

    dbcdb.vm.provider :vmware_fusion do |v, override|
      override.vm.box = "centos-6.7-x86_64-vmware"
      override.vm.box_url = "https://dl.dropboxusercontent.com/s/pr6kdd0nvzcuqg5/centos-6.7-x86_64-vmware.box"
    end

    dbcdb.vm.hostname = "dbcdb.example.com"
    dbcdb.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    dbcdb.vm.synced_folder "/Users/edwinbiemond/software", "/software"

    dbcdb.vm.network :private_network, ip: "10.10.10.8"

    dbcdb.vm.provider :vmware_fusion do |vb|
      vb.vmx["numvcpus"] = "2"
      vb.vmx["memsize"] = "4092"
    end

    dbcdb.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm"     , :id, "--memory", "4092"]
      vb.customize ["modifyvm"     , :id, "--name"  , "dbcdb"]
      vb.customize ["modifyvm"     , :id, "--cpus"  , 2]
    end

    dbcdb.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml;rm -rf /etc/puppet/modules;ln -sf /vagrant/puppet/modules /etc/puppet/modules"

    dbcdb.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "site.pp"
      puppet.options           = "--verbose --trace --hiera_config /vagrant/puppet/hiera.yaml"

      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }

    end

  end

end
