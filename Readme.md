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
This is what I will deploy (based on Techno Tim setup in [this video](https://www.youtube.com/watch?v=UoOcLXfa8EU) ) : 

![architecture](./k3s-architecture.png)

1. Terraform deploys 8 nodes : 6 for the K3s cluster, one Mysql server (I'm running K3s in HA mode, with external DB), and a proxy. 
2. A bunch of playbooks deploy the services : one for setting up mysql, one for setting up nginx in ha proxy mode, one to deploy the master nodes, and one to deploy the worker nodes. 

I'm cloning an existing template (Ubuntu 20.04), where I have a user (ansiblebot) with proper sudo privileges. This is the user that Ansible will use for the ```become``` commands. 

## Commands
The commands are fairly simple :

```
terraform apply -auto-approve
ansible-playbook -i inventory/hosts.ini -u ansiblebot playbook-mysql.yaml playbook-haproxy.yaml playbook-control-plane.yaml playbook-worker.yaml
```

I'm running terraform in auto-approve mode, which is fine in a home lab, but not in production or in a company lab where deleting resources may harm someone else's work. I do it, because I've been running the `apply` about 20 millions time by now, so I know the effects. Plus, it's a home lab, so if something goes wrong, I'll redo it again. And don't get me started on the fact that the db password is in clear in one of the file : yes, I KNOW. It's a lab. This setup is torn down and restarted on a daily basis, sometimes with a random password generated.

Ansible runs the commands in sequence, because the mysql and the haproxy have to be there before deploying the cluster.

## Troubleshooting
If needed, test the DB access from one of the control-plane nodes : 
```
mysql -u k3s  -h 192.168.1.65 --port=33306 -p -D k3s
```

If for some reason the deployment of the control nodes failed, connect to them and run ```/usr/local/bin/k3s-uninstall.sh```, fix the issue and restart the control plane playbook. 

