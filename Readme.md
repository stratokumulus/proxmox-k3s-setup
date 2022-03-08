# Why Proxmox VE ? 
 
Because I can. It's easy to install. It's easy to maintain. It's easy to operate. It's opensource. 'nuff said ... 

My homelab consist of two servers running Proxmox VE :
- a Dell R620 (2x E5-2680v2 12 cores, 192GB, 4x 600GB) 
- a Dell R630 (2x E5-2698v4 20 cores, 192G B, 8x 600 GB)

I'm constantly deploying new Kubernetes flavors, just to be able to study them, but each deployment takes time (OpenShift ! I'm looking at you). And I don't want both my hypervisors to be running every day, 24x7, so I need a way to deploy my environments automatically, along with the deployment of the Kubernetes workload. The second part is fairly easy if the kubeconfig points to the right cluster, a nice `kubectl apply -f` and presto, the workload is installed.

But what about the cluster config ?

Enter Terraform.  And enter Ansible. And enter Jenkins (ok, ok, that's a lot entering at once ... let's summarize :)

Enter Infrastructure as Code !

## Architecture
This is what I will deploy (based on Techno Tim setup in [this video](https://www.youtube.com/watch?v=UoOcLXfa8EU) , which is itself based on the [Rancher K3S HA installation doc](https://rancher.com/docs/k3s/latest/en/installation/ha/) ) : 

![architecture](./k3s-architecture.png)

1. Terraform deploys 8 nodes : 6 for the K3s cluster, one Mysql server (I'm running K3s in HA mode, with external DB), and a proxy. 
2. A bunch of playbooks deploy the services : one for setting up mysql, one for setting up nginx in ha proxy mode, one to deploy the master nodes, and one to deploy the worker nodes. 

| Name | Mac address | IP address | Role |
|------|-------------|------------|------|
| k3s-ctrl-1 | 7A:00:00:00:01:01 | 192.168.1.150 | Control plane #1 |
| k3s-ctrl-2 | 7A:00:00:00:01:02 | 192.168.1.151 | Control plane #2 |
| k3s-ctrl-3 | 7A:00:00:00:01:03 | 192.168.1.152 | Control plane #3 |
| k3s-cmp-1 | 7A:00:00:00:01:04 | 192.168.1.153 | Worker #1 |
| k3s-cmp-2 | 7A:00:00:00:01:05 | 192.168.1.154 | Worker #2 |
| k3s-cmp-3 | 7A:00:00:00:01:06 | 192.168.1.155 | Worker #3 |
| k3s-mysql | 7A:00:00:00:01:07 | 192.168.1.156 | External DB |
| k3s-nginx | 7A:00:00:00:01:08 | 192.168.1.157 | Load balancer |

Each VM is configured with a private Mac address (1st byte : 1st biff off, 2nd bit on). These Mac addresses are reserved on my DHCP server to provide the IP addresses you'll see in the file ```ìnventory/hosts.ini```.

## Template preparation

I'm cloning an existing template (Ubuntu 20.04), where I have a user (ansiblebot) with proper sudo privileges. This is the user that Ansible will use for the ```become``` commands. I haven't done it yet, but I'm planning on removing the sudo privileges for the ansiblebot user as a post install task.

Also installed docker on the box, along with additional tools I use from time to time. I could use two templates, one for the general purpose servers, and one for the cluster. Oh well, that'll do for now. 

I'm cloning this box 8 times, which takes about 1m30s on my R630 (linked clones, not full ones). The name of the template is defined in the terraform variables file. 

BTW, I've tried to make the k3s-mysql and k3s-nginx hosts as LXC containers, but the Telmate terraform provider offers less features for an Ansible-friendly installation (due to the Proxmox API ? dunno... ), so I've decided to make them low power hosts. 

## Commands
The commands are fairly simple :

```
terraform apply -auto-approve
ansible-playbook -i inventory/hosts.ini -u ansiblebot playbook-mysql.yaml playbook-haproxy.yaml playbook-control-plane.yaml playbook-worker.yaml
```

Ansible runs the commands in sequence, because the mysql and the haproxy have to be there before deploying the cluster.

## Fair warning

I'm running terraform in auto-approve mode, which is fine in a home lab, but not in production or in a company lab where deleting resources may harm someone else's work. I do it, because I've been running the `apply` about 20 millions time by now, so I know the effects. Plus, it's a home lab, so if something goes wrong, I'll redo it again. 

And don't get me started on the fact that the db password is in clear in one of the file : yes, I KNOW. It's a lab. This setup is torn down and restarted on a daily basis, sometimes with a random password generated. Use a vault when going to prod ! Never let your password in clear text in prod ! Do I have to tell you everything ???

## Troubleshooting
If needed, test the DB access from one of the control-plane nodes : 
```
mysql -u k3s  -h 192.168.1.65 --port=33306 -p -D k3s
```

If for some reason the deployment of the control nodes failed, connect to them and run ```/usr/local/bin/k3s-uninstall.sh```, fix the issue and restart the control plane playbook. 

