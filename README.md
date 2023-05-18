# Deploying WebApps With Gunicorn, Nginx & Infrastructure as Code 

This one goes out to all of those who would rather do things manually from the AWS console, because it's *"just quicker and easier"*. Nonsense, I say!!! 

While an **Infrastructure as Code (IaC)** approach does require more planning and time upfront, once you write a few templates, every single deployment from that point forward can be done ***BLAZINGLY FAST*** (Rust did not sponser this project).

For the sake of brevity, I'll only touch on the keypoints. Please feel free to go into the project files at any time if you need more context. Also feel free to make suggestions on how this walkthrough could be made better!

## Table of Contents

- [Project Overview](#project-overview)
- [Tools Used](#tools-used)
- [Terraform Infrastructure](#terraform-infrastructure)
- [Project File Structure](#project-file-structure)
- [Making Plays](#making-plays)
- [Configuring Gunicorn And Nginx](#configuring-gunicorn-and-nginx)
- [Conclusion](#conclusion)

## Project Overview

Using the DGN stack is a simple way of quickly deploying a webapp and IaC in general enables **stream-lined, repeatable deployments** that can easily be version controlled requires **minimal effort to alter**.

The steps we'll take look like this:

1. Create AWS infrastructure using Terraform.
2. Build config files and Ansible playbooks.
3. Use Ansible to install dependencies on ALL servers, and then restart instances.
5. Push project files from Master Node to Target Nodes using Ansible.
6. Modify a small handful of files per server to get Gunicorn and Nginx working smoothly.

By the end, we should have a system architecture like this:

![SystemArch](https://github.com/wrchasesims/CodePlatoon/blob/d86a8dd8cd22dafa6504b66b38be1cdfb54f9a58/assessments/assessment2/imgs/system_architecture.png)

Now then, let's dive into the tools we'll utilize to make the magic happen!

## Tools Used

- [Terraform](https://www.terraform.io)
- [Ansible](https://www.ansible.com)
- [AWS](https://aws.amazon.com)
- [Django](https://www.djangoproject.com)
- [Gunicorn](https://gunicorn.org)
- [Nginx](https://www.nginx.com)

![Stack](https://github.com/wrchasesims/CodePlatoon/blob/d86a8dd8cd22dafa6504b66b38be1cdfb54f9a58/assessments/assessment2/imgs/stack.png)

Please follow the links above if you're unfamiliar with any of these awesome tools!

## Terraform Infrastructure

Long story short, we'll be using **three** of the official [AWS Terraform Modules](https://registry.terraform.io/namespaces/terraform-aws-modules) to avoid reinventing the wheel - AKA writing our own resources from scratch.
We'll use the **VPC**, **Security Group** & **EC2 Instance** modules. All of the modules are declared in the **main.tf** file located within the terraform directory if you want to take a look!

### Diagram
![TFInfra](https://github.com/wrchasesims/CodePlatoon/blob/d86a8dd8cd22dafa6504b66b38be1cdfb54f9a58/assessments/assessment2/imgs/terraform-graph.png)
Image created with: [Terraform Visual](https://hieven.github.io/terraform-visual/)

The names may be a bit abstract due to using the modules... but dad-gum it, if it ain't broke don't fix it!
Note that this diagram doesn't necessarily show relations between the resources, simply the resources created.

Last thing here, pay attention to the **outputs** we get after running `terraform apply`

![TF Outputs](https://github.com/wrchasesims/CodePlatoon/blob/d86a8dd8cd22dafa6504b66b38be1cdfb54f9a58/assessments/assessment2/imgs/tf_outputs.png)

That should enable us to SSH into our new instances **without having to navigate to the AWS console**.

### VPC Module

This module handles creating the **VPC**, a **public subnet**, **routing tables**, etc. It also alters the **default security group**, which is then utilized by the **Master Node**.
The master node should only allow incoming traffic on **port 22 (SSH)**.

### Security Group Module

This is used to setup the **security group** (imagine that!) for the **target nodes**.
The target node ports start off with ports 22, 80 & 9876 all open.

- **Port 22** to allow us to run our **ansible playbooks/configure the servers**.
- **Port 9876** to test **Django/Gunicorn** functionality.
- **Port 80** will need to be open so that **Nginx** can listen for standard HTTP traffic.

After a dry run to make sure everything works flawlessly, we **alter the terraform security group so that only port 80 remains open**.

### EC2 Module

Nothing too special here. We call **two instances of this module** in **main.tf**: one creating the **master node** and the other creating the **two target nodes**.
All nodes are on the same public subnet within our VPC.

## Project File Structure

The easiest and most comfortable and organized way to handle a project like this is by doing all the 'development' upfront on your **local machine** - which is exactly what we'll do. After that, we'll **automate everything with Ansible playbooks** to quickly and easily configure our apps/servers. After testing everything, this could easily be turned into a **one-click deployment!** I voted against that for sake of better organization/testing.

![Project File Tree](https://github.com/wrchasesims/CodePlatoon/blob/d86a8dd8cd22dafa6504b66b38be1cdfb54f9a58/assessments/assessment2/imgs/file_tree.png)

Have you ever seen such a beautiful tree?!

But seriously... as you can see, we have our **Terraform files** in a directory to themselves and the remaining files are the few **configs/playbooks** we'll need.
Anything with a **.yaml** extension is an **ansible playbook**. The rest are various types of configs.

### Brief Description Of Config Files

- **env** -- holds environment variables which Django will use to authenticate with an RDS that was provisioned elsewhere (it's not in the Terraform infra).
- **gunicorn.service** -- .ini configuration file to enable Gunicorn to be ran as a background process (or daemon service). Also handles restarting.
- **proxy.conf** -- holds a snippet of info required to configure Nginx as our reverse proxy.
- **inventory.ini** -- see below.

## Making Plays

### Inventory.ini

**inventory.ini** is very important. It holds all the information that **allows Ansible to connect to our instances**, and **variables** that it can use to make our playbook code more **flexible**.
Remember to update the IP addresses with those of your servers!!!

![Inventory Contents](https://github.com/wrchasesims/CodePlatoon/blob/d86a8dd8cd22dafa6504b66b38be1cdfb54f9a58/assessments/assessment2/imgs/inv.png)

Within, we have **three groups ('master', 'webservers' & 'all:vars')**. All the hosts that belong to each group are listed below the group heading. The third group - **instead of holding info about servers** - is a collection of **variables** which Ansible can use on **all** of the hosts in the other groups.

### Ping Pong

First, **ping the servers** in your inventory file. Pinging them one at a time seems to be a cleaner way for the initial ping if SSH keys are in the mix.


`ansible master_node -m ping -i proj_files/configs/inventory.ini`

`ansible node1 -m ping -i proj_files/configs/inventory.ini`

`ansible node2 -m ping -i proj_files/configs/inventory.ini`


![PingTest](https://github.com/wrchasesims/CodePlatoon/blob/d86a8dd8cd22dafa6504b66b38be1cdfb54f9a58/assessments/assessment2/imgs/pingpong.png)

### Running The First Play!

This is where the fun begins. Our first playbook - **initial_setup.yaml**.
I'd waste your time telling you what the playbook does, but one beautiful aspects of Ansible playbooks is that they explain what they're doing every step of the way. Try running it to see what I mean!

from the **root directory (where initial_setup.yaml lives)**, run:

`ansible-playbook initial_setup.yaml -i proj_files/configs/inventory.ini`

![Inventory](https://github.com/wrchasesims/CodePlatoon/blob/aba8f6596512bfff9ea32b7f9675b852729adabd/assessments/assessment2/imgs/1st_playbook.png)

Something I will touch on is the **REE-boot task** at the end. This may seem like Ansible is hanging - **and actually, it is** - but for good reason. That task is written in a way so that it reboots the target instances and then **waits for them to come back online**. It then publishes a debug message to your terminal with the uptime of each target, so you can be sure that it rebooted.

## Configuring Gunicorn And Nginx

Once again, **the plays are self-describing** and do all the work from here. Just goes to show how ***powerful*** Ansible really is!
Go ahead and **run the last two plays**, then throw a target server IP address into your browser..

`ansible-playbook proj_files/ansible/2_env_setup.yaml -i proj_files/configs/inventory.ini`

`ansible-playbook proj_files/ansible/3_gunginx.yaml -i proj_files/configs/inventory.ini`

## Conclusion

**Hooray! You did it!** You now have a webapp deployed to 2 AWS instances that are being load balanced and proxied by Nginx and served up by Gunicorn and Django.

Feel free to contact me if you have any questions/recommendations, or go ahead and make a pull request if you'd like to contribute!
