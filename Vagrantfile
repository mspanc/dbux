VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider "virtualbox" do |vbox|
    vbox.memory = 1024
    vbox.cpus   = 4
  end

  config.vm.box = "ubuntu/trusty64"

  config.vm.provision "ansible" do |ansible|
    ansible.sudo = true
    ansible.playbook = "ansible.yml"
  end
end
