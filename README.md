# azspark

## 🚚 Tech Challenge - DTB Hub

This document describes the implementantion process of a Spark cluster with 1 (one) master node and 2 (two) slaves nodes.

The main documentation used to understand the basics of the software installation, configuration and administration can be found at:

- Apache Spark Home Page: <https://spark.apache.org>
- Installation Process: <https://spark.apache.org/docs/2.4.0/#launching-on-a-cluster>

The infrastructure used to deploy the solution was entirely based on Microsoft Azure. A free / trial account was used in order to implement the network, virtual machines, persistence (storage) and all other computational resources used in this laboratory.

## ☁ How to implement the Azure Virtual Infrastructure

1. From the Azure Portal, start a Cloud Shell terminal (the system will create a Resource Group and a persistence layer automaticaly in order to launch the application).

2. Upload the file "deploySparkInfrastructure.ps1" using the upload option found at the terminal's menu bar.

3. Move the file from your home directory to the "clouddrive" directory and execute the script:

~~~~powershell
PS Azure:\> cd $HOME
PS /home/username> mv ./deploySparkInfrastructure.ps1 ./cloudrive
PS /home/username> cd ./clouddrive/
PS /home/username/clouddrive> ./deploySparkInfrastructure.ps1
~~~~

## 💡 How to implement the Spark cluster

An Ansible Playbook is available in order to deploy the Spark cluster. However, some pre-deployment steps are necessary in order to install and configure the Ansible itself.

1. Using the Cloud Shell, collect the public IP's associated with each Virtual Machine deployed:

~~~~powershell
PS Azure:\> Get-AzPublicIpAddress -ResourceGroupName "sparkResourceGroup" | Select "Name", "IpAddress"

Name                IpAddress
----                ---------
sparkNameDNS-master XXX.XXX.XXX.XXX
sparkNameDNS-slave1 YYY.YYY.YYY.YYY
sparkNameDNS-slave2 ZZZ.ZZZ.ZZZ.ZZZ
~~~~

2. Log in on each Virtual Machine and create a SSH Key without password:

~~~~bash
sparkadmin@master:~$ ssh-keygen -t rsa -b 2048
~~~~

~~~~bash
sparkadmin@slave1:~$ ssh-keygen -t rsa -b 2048
~~~~

~~~~bash
sparkadmin@slave2:~$ ssh-keygen -t rsa -b 2048
~~~~

3. Copy the public keys of each Virtual Machine at the ~/.ssh/authorized_keys file of every node. This way, Ansible will be able to execute the playbook without asking for a password.

The next steps are performed only on the master node:

4. Install Ansible:

~~~~bash
sparkadmin@master:~$ sudo apt-get install ansible -y
~~~~

5. Copy the "hosts" file to /etc/ansible/. Also, copy the ansible.cfg file to the same directory, or just edit the file and change the "host_key_checking" option to "false".

6. Deploy the Spark cluster running the "deploySparkCluster.yml" playbook:

~~~~bash
sparkadmin@master:~$ ansible-playbook deploySparkCluster.yml
~~~~

7. From any browser, access the Spark Dashboard via ```http://<master_public_ip>:8080```. The Worker's dashboard can be accessed via ```http://<slave_public_ip>:8081```.
