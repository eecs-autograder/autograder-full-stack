This repository contains Docker and other configuration files needed to run and deploy the autograder system.

# Dev Setup

This tutorial will walk you through installing and running the autograder on your local machine.

## System Requirements
**Supported Operating Systems:**
- Ubuntu 16.04 (18.04 will probably work)
- OSX 10.11.6 or later

It _might_ be possible to run the development stack on Windows using Docker CE for Windows. If you decide to try this, you're on your own.

Environments that will **NOT** work:
- Linux Subsystem for Windows (Do NOT attempt!)
- Cygwin (No way)
- CAEN Linux (Plz no)

## Install Docker Community Edition
Ubuntu: https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1

OSX: https://docs.docker.com/docker-for-mac/install/

## Clone and checkout
```
git clone --recursive git@github.com:eecs-autograder/autograder-full-stack.git
cd autograder-full-stack
git checkout master

cd autograder-server
git checkout develop 
cd ..
cd autograder-website
git checkout develop 
cd ..
```
If you accidentally left out the `--recursive` flag, you can get the same effect by running this command in the autograder-full-stack directory:
```
git submodule update --init
```

## Run the development stack
```
docker-compose -f docker-compose-dev.yml build
docker-compose -f docker-compose-dev.yml up
```
This will start the development stack in the foreground.
Note that you _usually_ won't need to rebuild the development stack.
If you run into a situation where changes aren't automatically detected,
kill the stack with Ctrl+C and rerun the two commands above.

Times when a rebuild is required:
- Changing the requirements.txt file in autograder-server
- Changing the package.json file in autograder-website

## Finish setting up the database
After starting the docker images with the ``docker-compose -f docker-compose-dev.yml up`` command, you should run these commands in a _new_ terminal window.

Apply Django migrations:
```
docker exec -it ag-dev-django python3 manage.py migrate
```
Start a Python shell inside the ag-dev-django container:
```
docker exec -it ag-dev-django python3 manage.py shell
```
In the Python shell, create a course and add yourself as an administrator:
```
from autograder.core.models import Course
from django.contrib.auth.models import User

me = User.objects.get_or_create(username='jameslp@umich.edu')[0]
course = Course.objects.validate_and_create(name='My Course')
course.admins.add(me)
```
Note, you can use a different username if you like. If you do, keep track of what you chose, as you'll need it when we visit the autograder in a browser.

## Load the web page
Navigate to `localhost:4200` in your browser.

If you want to switch ports, you'll need to edit the file `autograder-full-stack/docker-compose-dev.yml`.
Under the `website` block, change the `--port` option in the `command` settings. For example, to change the port to 9001:
```
services:
  website:
    ...
    command: ./node_modules/.bin/ng serve --port 9001 --host 0.0.0.0
    ...
```
Then, navigate to `localhost:9001` in your browser.

## "Authenticate"
The development stack allows users to manually specify the user they wish to log in as.
In order to specify your desired username, you'll need a browser plugin that lets you edit cookies, such as the
[EditThisCookie](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg?hl=en) for Google Chrome.

Using the plugin, set a cookie with key `username` and value `<desired username>`.
If no cookie is set, it will authenticate you as jameslp@umich.edu by default.
If you specified a different username when setting up the database, use that username
as the value for the cookie you set.

### Switching between real and fake authentication
In docker-compose-dev.yml, change the `USE_REAL_AUTH` variable in the "environment" block inside of the "django" service definition:
```
django:
    ...
    environment:
      # Set to false to disable real authentication. Any other string value
      # will enable real authentication.
      # Then, using a browser plugin such as EditThisCookie, set the
      # cookie "username=<email>" to set which user you want to
      # authenticate as.
      USE_REAL_AUTH: 'false'
```
To use the fake cookie authentication, leave USE_REAL_AUTH as `'false'`, otherwise, set it to `'true'` to use real authentication.
You will most likely need to "stop" and "up" your stack for the change to take effect.

## Adding New Docker Images 

To add a new docker image to the autograder, first build and your images and push them somewhere accessible by your servers. Then, use the `sandbox_docker_image.py` script at https://github.com/eecs-autograder/autograder-contrib to register the metadata of those images.

# Production Setup

## System Requirements
**Supported Operating Systems:**
- Ubuntu 16.04 (18.04 will probably work)

## Install Docker Community Edition and Docker Compose
Docker CE: https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1
Docker Compose: https://docs.docker.com/compose/install/

## Clone the Source Code
```
git clone --recursive git@github.com:eecs-autograder/autograder-full-stack.git
cd autograder-full-stack
```
The autograder-server and autograder-website submodules should automatically be set to the correct commit. You do not need to checkout a branch in them.

If you accidentally left out the `--recursive` flag, you can get the same effect by running this command in the `autograder-full-stack` directory:
```
git submodule update --init
```

### Updating the Source Code
In order to update the to the latest stable release, run this command in the `autograder-full-stack` directory:
```
git pull
git submodule update --remote
```

## Configuration
### Increase the nofile limit on your servers
Add these two lines to `/etc/security/limits.conf`:
```
*                soft    nofile          1000000
*                hard    nofile          1000000
```
If you don't do this, then you will experience difficult-to-debug issues.

### Domain Names

The server name is set to `autograder.io` by default.
Make the following changes to use a non-default server name.  
Please change $SERVER to your server's DNS name. All paths here are relative to `autograder-full-stack`.  

  * Update `SITE_DOMAIN=$SERVER` in `./autograder-server/_prod.env`
  * Update `ALLOWED_HOSTS=$SERVER` in `./autograder-server/_prod.env`
  * Update `server_name` in `./nginx/production/conf.d/default.conf` to your server name

### SSL Certs

Enabling SSL certs requires:
  * Create your ssl certs and add them to `/etc/ssl`. We will mount this directory to `/etc/ssl` in the docker container.
  * Edit `ssl_certificate` and `ssl_certificate_key` in  `./nginx/production/conf.d/default.conf` to point to your ssl certs. 
    * NOTE: The path to the certs in this file is the path inside the docker container.
  * (Optional) In `docker-compose.yml`, edit the `volumes` block in the `nginx` service block if your ssl certs aren't in `/etc/ssl`. For example:
    ```
    services:
      nginx:
        ...
        volumes:
          - /host/path/to/certs:/etc/ssl
          ...
    ```

### Google Auth

To set up Google's authentication, you will need to follow roughly the following steps:

 * Log into the [Google API Console](https://console.developers.google.com)
 * Create a new project with your correct domain login
 * Enable the People API service for your project
 * Under the "Credientials" tab, add oauth credientials for a web-service. 
 * Add `https://$WEBSITE/api/oauth2callback/` as an 'Authorized rediect URIs'
 * Download the .json oauth file (far right download arrow)
 * Move the .json oauth file to ./autograder-server/autograder/settings/oauth2_secrets.json
 * Update `OAUTH2_SECRETS_FILENAME=oauth2_secrets.json` in ./autograder-server/_prod.env

 ### Other Tweaks
  * In `./autograder-server/uwsgi/uwsgi.ini`, adjust `processes` based on how many cpu cores your machine has.
    * NOTE: For a single-server deployment, you should be conservative with this value.
  * (Optional) increase `client_max_body_size` in `./nginx/production/conf.d/default.conf`.
  * (Optional) In `./autograder-server/autograder/core/constants.py`, tune `MAX_VIRTUAL_MEM_LIMIT`, `MAX_SUBPROCESS_TIMEOUT`, and `MAX_PROCESS_LIMIT` to your liking.
  * (Optional) Adjust the number of grader workers in `docker-compose.yml`:
    ```  
    grader:
      # *** Change the value *** of -c to set the number of workers.
      # Even with many CPU cores, be conservative with this value.
      command: /usr/local/bin/celery -A autograder worker -n submission_grader@%h --loglevel=info -c 4

    deferred_grader:
      # This -c value can be lower than the other one. If resources are tight, set to 1 or 2
      command: /usr/local/bin/celery -A autograder worker -Q deferred,rerun -n deferred@%h --loglevel=info -c 4
    ```
  * You may need to create the swarm network that `docker-compose.yml` expects:
  ```
  docker network create ag-swarm-network 
  ```

## Run the Production Stack
```
docker-compose build
docker-compose up -d
```

To update the containers:
```
docker-compose stop
docker-compose build
docker-compose up -d
```

Other useful commands:
```
# View a list of running containers
docker ps

# View the logs for a container
docker logs -f <container name>
```
## Finish setting up the database
After starting production stack, you should run these commands.

Apply Django migrations:
```
docker exec -it ag-django python3 manage.py migrate
```
Start a Python shell inside the ag-django container:
```
docker exec -it ag-django python3 manage.py shell
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

## Other Things to Know
### Useful scripts
A variety of scripts that use the web API can be found at `https://github.com/eecs-autograder/autograder-contrib` and `https://gitlab.eecs.umich.edu/akamil/autograder-tools`. 
  * IMPORTANT: Make sure to use the correct URL for your deployment. In the former set of scripts, this is configurable with command-line arguments. In the latter, you may need to modify the source code.

### Giving a user permission to create courses
Run the following in a django shell (`docker exec -it ag-django python3 manage.py shell`):
```
from django.contrib.auth.models import User, Permission
# UPDATE the email address
user = User.objects.get(username='@umich.edu')
user.user_permissions.add(Permission.objects.get(codename='create_course'))
```

### Submissions not being processed for one project
This issue is difficult to reproduce, so we're uncertain as to whether it has been fixed. Occasionally a new project won't be correctly registered with the grading workers, and so submissions won't get past "queued" status. To manually register the project, run the following in a django shell:
```
from autograder.grading_tasks.tasks import register_project_queues
# UPDATE the project_pks list. The project primary key can be found in the url when viewing the project on the website.
register_project_queues(project_pks=[339])
```

### Submission(s) stuck at "being graded" status
Sometimes a power bump can prevent grading tasks from finishing. Run the following in a django shell to restart the grading process for a student's submission:
```
from autograder.core.models import *
from django.contrib.auth.models import User

# UPDATE the email address
student = User.objects.get(username='<email address>')
# UPDATE the project pk
stuck = student.groups_is_member_of.get(project=<project_pk>).submissions.filter(status=Submission.GradingStatus.being_graded)

print(len(stuck))  # Should be no more than 1

for submission in stuck:
  submission.status = Submission.GradingStatus.received
  submission.save()
```
