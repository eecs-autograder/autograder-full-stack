This repository contains Docker and other configuration files needed to run and deploy the autograder system.

# Setup

This tutorial will walk you through installing and running the autograder on your local machine.

## System Requirements
**Supported Operating Systems:**
- Ubuntu 16.04
- OSX 10.11.6 or later

It _might_ be possible to run the development stack on Windows using Docker CE for Windows. If you decide to try this, you're on your own.

Environments that will **NOT** work:
- Linux Subsystem for Windows (Do NOT attempt!)
- Cygwin (No way)
- CAEN Linux (Plz no)

Supported Browsers:
- Google Chrome 65 or later
- Mozilla Firefox 54 or later

## Install Docker Community Edition
Ubuntu: https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1

OSX: https://docs.docker.com/docker-for-mac/install/

## Clone and checkout
```
git clone --recursive git@github.com:eecs-autograder/autograder-full-stack.git
cd autograder-full-stack
git checkout develop

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

# Adding New Docker Images 

To add a new docker image to the autograder, first load the image into docker.  Then you will to 
manually modify the following files to include your new image name:

  * ./autograder-server/autograder/core/constraints.py
  * ./autograder-website/autograder/constraints.ts
  * ./autograder-website/autograder/ag_models/ag_tests.ts
  
  
# Configurations for Non-UMICH servers

**Note:** This assumes you are attempting a production-build system.  
Development builds do not require these steps. 

### Domain Names

The following changes were necessary to use a non-default server name.  
Please change $SERVER to your server's DNS name.  

 * add 'SITE_DOMAIN=$SERVER' to ./autograder-server/_prod.env
 * update 'ALLOWED_HOSTS=$SERVER' in ./autograder-server/_prod.env
 * update the allowed domains in autograder-server/autograder/rest_api/views/oauth2callback.py
 * edit ./nginx/production/conf.d/default.conf to reflect the new certs

### SSL Certs

Enabling SSL certs requires:
 * adding new ssl certs.  Let's assume they are at /etc/ssl/certs/host.{cert,key}
 * edit ./nginx/production/conf.d/default.conf to reflect the new certs
 * (optional) edit docer-compose.yml to map a new volumn if your new ssl certs are in a non-default directory

### Google Auth

To use Google's authentication, you will need to follow roughly the following steps:

 * log onto the [Google API Console][https://console.developers.google.com]
 * create a new project with your correct domain login
 * add Google+ API service to your project
 * Under the "Credientials" tab, add oauth credientials for a web-service. 
 * Add 'https://$WEBSITE/oauth2callback/' as an 'Authorized rediect URIs'
 * download the .json oauth file (far right download arrow)
 * move the .json oauth file to ./autograder-server/autograder/settings/oauth2_secrets.json
 * update 'OAUTH2_SECRETS_FILENAME=oauth2_secrets.json' in ./autograder-server/_prod.env

## Switching to production

You might need to run this when switching to production mode

``` docker network create ag-swarm-network ```	
