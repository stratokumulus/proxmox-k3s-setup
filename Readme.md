# Why Proxmox VE ? 

Because I can. It's easy to install. It's easy to maintain. It's easy to operate. It's opensource. It forms clusters. So yeah, why not ?

My homelab consist of two Dell R6x0 servers running Proxmox VE 7 (with 192GB RAM each, and plenty of disk space). I have a user with proper rights (```terraform-prov```) that I use to automate VM creation. 

I'm constantly testing new Kubernetes flavors, just to be able to study them, search for some specific feature, ...  but each manual deployment takes time (OpenShift ! I'm looking at you). And I don't want both my hypervisors to be running every day, 24x7, so I need a way to deploy my environments automatically, quickly, along with the deployment of the Kubernetes workload. The second part is fairly easy if the kubeconfig points to the right cluster: a nice `kubectl apply -f` and presto, the workload is installed.

But what about the cluster deployment ?

Enter Terraform.  And enter Ansible. And enter Jenkins (ok, ok, that's a lot entering at once ... let's summarize :)

Enter Infrastructure as Code !

## Architecture

I'm deploying a few devices : control plane nodes, worker nodes, longhorn nodes. Based on the mood of the day, I device how many of each I want to deploy ... 

I'm forcing the MAC addresses and the Proxmox VM ID to keep things tidy and organized (all my VMs are close to one another in Proxmox this way). But it's totally fine to use outputs to read the IP addresses of the nodes once they are created. That works too, but then you'll have to update the DNS dynamically, and my infra doesn't allow that (yet ! PiHole, you're next on my thing to automate !)

Each VM is configured with a private Mac address (1st byte : 1st bit (or LSB) : off, 2nd bit : on), I do this to easily sort lab VMs belonging to specifig tests (f.i., my OpenShift lab has addresses in the 7A:..:**02**:xx range). These Mac addresses are then reserved on my DHCP server to provide the lab IP addresses. 

## Template preparation

I'm cloning an existing template (Ubuntu 20.04), where I have a user (ansible) with proper sudo privileges, and a configured SSH key. This is the user that Ansible will use for the ```become``` commands. I haven't done it yet, but I'm planning on removing the sudo privileges for the ansiblebot user as a post install task. And yes, it's totally possible to deploy using an ISO file and cloud-init. I'm doing it in another one of my repo, but haven't consolidated all that yet. 

Also installed docker on that template, along with additional tools I use from time to time (netstat for instance). 

BTW, I've tried to make the k3s-mysql and k3s-nginx hosts as LXC containers, but the Telmate terraform provider offers less features for an Ansible-friendly installation (due to the Proxmox API ? dunno... ), so I've decided to make them low power hosts. 

## Commands
The commands are fairly simple :

```
terraform apply 
```

Ansible runs the commands in sequence, because the mysql and the haproxy have to be there before deploying the cluster. It just waits 180 seconds before starting the playbook.


## Todo

- [ ] A Jenkins pipeline
- [ ] use dynamically assigned IP addresses. Static IPs are for the lazy (plus, it won't work for a cloud deployment)
- [ ] remove sudo privileges to ansiblebot user once provisioning is done
- [ ] go get a coffee. There's never enough coffee on any given day
- [ ] make deployment accross multiple proxmox hosts - should be easy, the target_host could be part of the VM var definition ?
- [ ] convert to a cloud deployment
- [ ] add Rancher as the UI ... not really tempted as I prefer CLI
- [ ] improve the Ansible code. I'm not using variables the Ansible way. Shame on me ...

## Troubleshooting

The DB must be properly configured and avaiable from the control plane nodes. If it's not, then you'll get an error in ```systemctl status k3s``` complaining about connection to the mysql box closed/rejected/... So test the DB access from one of the control-plane nodes : 

First to the mysql server :
```
mysql -u k3s  -h 192.168.1.156  -p -D k3s
```
Then to the HA Proxy :
```
mysql -u k3s  -h 192.168.1.157 --port=33306 -p -D k3s
```

Ports, names, and IPs are the ones configured in my project, adapt these commands to your own config. 

If for some reason the deployment of the control nodes failed, connect to each one of them and run ```/usr/local/bin/k3s-uninstall.sh```, find the root cause of the failure, fix it, and just restart the control plane playbook, followed by the worker node playbook.

