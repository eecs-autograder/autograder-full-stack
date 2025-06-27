# Production Deployment Using Docker Swarm

Using Docker Swarm to deploy this codebase on more than one machine
can significantly improve performance and stability.
This document explains the steps required to do so.

## Requirements and Recommendations
- At least 3 servers running a supported Ubuntu LTS (22 or 24 at time of writing)
    - The server(s) hosting high-load parts of the system (e.g. database, webserver)
    should have a healthy amount of RAM and a fast processor.
    - The servers used as tiny grading workers can be small (e.g. a quad-core CPU, 16GB RAM).
      For grading workers with higher concurrency, you'll want more than that.
    - Disk space is most important for the output and submitted files stored by the
    Django application and for the database. The grading workers don't need much disk space.
- The servers should all be able to communicate with each other over a network.
Only the swarm node labelled `webserver` (more on labels later) needs to accept incoming
traffic on ports 80 and 443.

## First Steps
Follow the instructions in [this tutorial](./production_first_steps.md) for the
server that you want use as swarm manager.

## Other Tweaks
* In `docker-compose.yml`, adjust the value of the `--workers=xx` flag
  to set the number of gunicorn workers.
  ```
  django:
    ...
    command: guicorn --workers=<number of workers> ...
    ...
  ```
* Update the value of the `SYSADMIN_CONTACT` variable in `./ag-website-vue/src/constants.ts` to refer
  to your system administrator.
* (Optional) increase `client_max_body_size` in `./nginx/production/conf.d/default.conf`.
* (Optional) In `./autograder-server/autograder/core/constants.py`, tune `MAX_SUBPROCESS_TIMEOUT` to your liking. Set the corresponding values in `./ag-website-vue/src/constants.ts` as well.
* (Optional) Adjust the number of grader workers in `docker-compose.yml`:
    ```
    grader:
      # *** Change the value *** of -c to set the number of workers.
      # Even with many CPU cores, be conservative with this value.
      command: /usr/local/bin/celery -A autograder worker -n submission_grader@%h --loglevel=info -c 2

    deferred_grader:
      # This -c value can be lower than the one for `grader`.
      # If resources are tight, set to 1 or 2.
      command: /usr/local/bin/celery -A autograder worker -Q deferred -n deferred@%h --loglevel=info -c 1

    rerun_grader:
      # This -c value can be lower than the one for `grader`.
      # If resources are tight, set to 1 or 2.
      command: /usr/local/bin/celery -A autograder worker -Q rerun -n rerun@%h --loglevel=info -c 1

    fast_grader:
      command: /usr/local/bin/celery -A autograder worker -n fast_submission_grader@%h --loglevel=info -c 1
    ```

## Install Docker Community Edition
Install Docker on every server you want to have in the swarm.

https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1

Here is a summary of the commands you'll need from the above link:
```
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo usermod -aG docker $(logname)
```

## Increase the nofile Limit
Add these two lines to `/etc/security/limits.conf` on each server:
```
*                soft    nofile          1000000
*                hard    nofile          1000000
```
If you don't do this, then you will likely experience difficult-to-debug issues
on your grading workers.

## Initialize the Swarm
See https://docs.docker.com/engine/swarm/swarm-tutorial/ for full details.

Here is a summary of the steps from the above link:
1. Get the IP address of the machine that will be the swarm manager.
1. Initialize the swarm:
    ```
    docker swarm init --advertise-addr <MANAGER-IP>
    # Print a summary of nodes in the swarm
    docker node ls
    ```
1. Get the command needed for workers to join the swarm:
    ```
    # Copy the printed command to your clipboard
    docker swarm join-token worker
    ```
1. On each of your machines that will be worker nodes, run the command
printed in the previous step.
1. On the swarm manager node, run this command to create the swarm network:
```
docker network create ag-swarm-network --driver overlay
```

## Set Up NFS
First, clone the source code on one of your servers (e.g., the swarm manager node):
```
git clone --recursive https://github.com/eecs-autograder/autograder-full-stack.git
```

See https://help.ubuntu.com/lts/serverguide/network-file-system.html for full details.

Here is a summary of the steps from the above link:
1. Install NFS
    ```
    sudo apt install nfs-kernel-server
    ```
1. On the machine where you cloned the source code, edit `/etc/exports` and add
the following entry (all one line), replacing {home} with the absolute path to your home directory:
    ```
    /{home}/autograder-full-stack    *(rw,sync,no_root_squash,no_subtree_check)
    ```
1. Start the NFS server
    ```
    sudo systemctl enable nfs-kernel-server.service
    sudo systemctl start nfs-kernel-server.service
    ```
1. Create the autograder-full-stack directory and install nfs-common on all the remaining servers:
    ```
    mkdir $HOME/autograder-full-stack
    sudo apt install -y nfs-common
    ```
1. Mount the exported directory on those servers by adding the following entry to `/etc/fstab` on those servers, replacing {home} with the absolute path to your home directory and {server} with the hostname of the server exporting the directory:
    ```
    {server}:/{home}/autograder-full-stack /{home}/autograder-full-stack nfs rw,hard,intr 0 0
    ```
    Then, reboot the machine or run `sudo mount -a`.

## Label the Nodes
In order to avoid extra config file changes, we will apply labels to our nodes
to tell Docker Swarm which machine(s) to run which service(s) on.

__Note__: To enable "tiny" workers, uncomment the `tiny_grader`, `tiny_fast_grader`, `tiny_deferred_grader`, and `tiny_rerun_grader` blocks in `docker-compose.yml`. We use the "tiny" labels on NUCs in our swarm that are suited for grading one submission at a time.

Here is a list of all the labels that should be applied as needed:
- `registry`: Stores and serves Docker images needed to create services.
- `webserver`: The reverse proxy that handles incoming web traffic and the webserver that serves the frontent application.
- `django_app`: The Django backend application.
- `database`: The Postgres database.
- `cache`: The Redis cache.
- `rabbitmq_broker`: The Rabbitmq async task broker.
- `small_tasks`: Various background tasks such as queueing submissions, updating submission statuses, and building grade spreadsheets and zips of submitted files.
- `grader`: Grading worker for non-deferred tests.
- `tiny_grader`: Like `grader`, but only runs one task at a time.
- `fast_grader`: Dedicated worker for submissions with a low worst-case runtime.
- `tiny_fast_grader`: Like `fast_grader`, but only runs one task at a time.
- `deferred_grader`: Grading worker for deferred tests.
- `tiny_deferred_grader`: Like `deferred_grader`, but only runs one task at a time.
- `rerun_grader`: Grading worker for re-running tests.
- `tiny_rerun_grader`: Like `rerun_grader`, but only runs one task at a time.
- `image_builder`: Processes custom sandbox image build tasks.
- `custom_image_registry`: A Docker registry that stores custom sandbox images.

To apply a label to a node, run this command, replacing `{label}` and `{node hostname}`
with the label to apply and the hostname of the node:
```
docker node update --label-add {label}=true {node hostname}
```

To remove a label, run:
```
docker node update --label-rm {label} {node hostname}
```

### Label Recommendations
- The `database`, `registry`, `cache`, `rabbitmq_broker`, and `custom_image_registry` labels should be applied to __ONE NODE EACH__. If you ever change which node has the `database` and `registry` labels, you will need to migrate that data to the new server.
- Do NOT put `grader`/`tiny_grader`/`deferred_grader`/`tiny_deferred_grader` on the same server. Each node intended as a grading worker should have at most one of these labels.

## Create the Registry Service
Run the following command:
```
docker service create --name registry --publish 5000:5000 --mount type=volume,source=ag-registry,destination=/var/lib/registry --constraint 'node.labels.registry == true' registry:2
```

## Build and Deploy the Stack
Run these commands in the `autograder-full-stack` directory of your manager node. You will
need to rerun these commands every time you update the source code.
```
# Build the images
docker-compose build

# Push the images to the registry
docker-compose push

# Deploy the stack
docker stack deploy -c docker-compose.yml ag-stack

# View the list of running services
docker service ls
```
Note: You'll also need to apply database migrations. See the next section for instructions.

## Finish setting up the database
On the node labelled `django_app`, apply the database migrations. You should do this every time you update the source code:
```
docker exec -it ag-stack_django.1.$(docker service ps -f 'name=ag-stack_django.1' ag-stack_django -q --no-trunc | head -n1) python3 manage.py migrate
```

If this is a new deployment with no existing data, you'll need to create a course and add yourself to it as an admin. Start a Python shell inside the Django container:
```
docker exec -it ag-stack_django.1.$(docker service ps -f 'name=ag-stack_django.1' ag-stack_django -q --no-trunc | head -n1) python3 manage.py shell
```
In the Python shell, make yourself a superuser, create a course, and add yourself as an administrator:
```
from autograder.core.models import Course
from django.contrib.auth.models import User

# Substitute your email address
me = User.objects.get_or_create(username='jameslp@umich.edu', is_superuser=True)[0]
course = Course.objects.validate_and_create(name='My Course')
course.admins.add(me)
```
