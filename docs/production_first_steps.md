# Production Deployment: First Steps

This document details the required first steps for setting up a production
deployment. For swarm deployment, follow these instructions for the machine
you will use as swarm manager.

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
If you don't do this, then you will likely experience difficult-to-debug issues.

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

### Configure an OAuth2 Provider
Autograder.io currently supports Google and Microsoft Azure as auth providers.
Set `OAUTH2_PROVIDER=google` or `OAUTH2_PROVIDER=azure` in
`./autograder-server/_prod.env` to choose your provider.

**Google**

To set up Google's authentication, you will need to follow roughly the following steps:

 * Log into the [Google API Console](https://console.developers.google.com)
 * Create a new project with your correct domain login
 * Enable the People API service for your project
 * Under the "Credientials" tab, add oauth credientials for a web-service.
 * Add `https://$WEBSITE/api/oauth2callback/` as an 'Authorized rediect URIs'
 * Download the .json oauth file (far right download arrow)
 * Move the .json oauth file to ./autograder-server/autograder/settings/oauth2_secrets.json
 * Update `OAUTH2_SECRETS_FILENAME=oauth2_secrets.json` in ./autograder-server/_prod.env

**Microsoft Azure**

Detailed instructions for configuring an Active Directory app can be found at
https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-spa-app-registration

You will need to follow roughly the following steps:

* In the Azure portal, create an Azure app.
* Generate a client secret under the "Certificates & secrets" section.
* Edit `./autograder_server/autograder/settings/oauth2_secrets.json` to have
  the following contends, replacing `$CLIENT_ID` with the Azure Application ID,
  `$SECRET` with the client secret you created in the previous step, and `$DOMAIN`
  with your deployment domain:
  ```
  {
      "web": {
        "client_id":"$CLIENT_ID",
        "auth_uri":"https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
        "token_uri":"https://login.microsoftonline.com/common/oauth2/v2.0/token",
        "client_secret":"$SECRET",
        "redirect_uris":["https://$DOMAIN/api/oauth2callback/"],
        "javascript_origins":[]
      }
  }
  ```

### Configure SMTP Server
In order for submission email receipts to work, you must set up an SMTP server
that all of your servers can access on the network. Uncomment and update the
following environment variables in ./autograder-server/_prod.env to point to
your SMTP server:

`EMAIL_HOST`: The hostname for the SMTP server.
`EMAIL_HOST_PASSWORD`: The password for the SMTP server. Leave commented out if
there is no password.
`EMAIL_HOST_USER`: The username for the SMTP server.
`EMAIL_PORT`: The port for the SMTP server.
`EMAIL_FROM_ADDR`: The "from" address for submission email receipts. Defaults
to "admin@autograder.io". Change this to an email address you control.

### (Optional) Tune Resource-limit Environment Variables
Depending on how many servers you are using for deployment and the specs of
those servers, you may wish to adjust the resource limits placed on Docker
containers. To change these values, uncomment the appopriate environment
variable in ./autograder-server/_prod.env and set its value as you see fit:

`SANDBOX_MEM_LIMIT`: The physical memory limit (using cgroups) placed on
Docker containers used to grade submissions. For single-server deployment,
re recommend setting this to a value such that grading workers can never use
more than 50% of total system memory. Defaults to 4gb. Setting this value too
low won't cause programs to crash outright, but rather can cause more frequent
page faults and thereby decrease performance.

See https://docs.docker.com/config/containers/resource_constraints/#memory for full details.
`SANDBOX_PIDS_LIMIT`: The maximum number of processes for a container (limited
using cgroups). Be careful not to set this value too low, otherwise test cases
may not run properly. Defaults to 512.

`IMAGE_BUILD_MEMORY_LIMIT`: Similar to `SANDBOX_MEM_LIMIT`, but for building
custom images. Defaults to 4gb

`IMAGE_BUILD_NPROC_LIMIT`: the max number of processes when building a custom
image (limited using ulimit). Defaults to 1000.

`IMAGE_BUILD_TIMEOUT`: The time limit for building a custom image, in seconds.
Defaults to 600.

## Generate Secrets
Generate the Django secret key and a GPG key pair for signing emails.
First, install the following dependencies on your server (NOT in a docker container).
1. [GPG](https://gnupg.org/)
2. Python 3.8 and Pip
3. Using pip, install [Django](https://www.djangoproject.com/download/) (latest 3.1.x version) and [python-gnupg](https://pypi.org/project/python-gnupg/)
    ```
    pip install Django python-gnupg
    ```

Then run `generate_secrets.py`:
```
cd autograder-server

# Note also that this step requires a lot of entropy to generate the GPG keys.
# Try running commands such as `ls -R / > /dev/null` or downloading a large
# file while the command below is running. Even so, it can take a long time
# for the key generation to finish.
# See https://stackoverflow.com/questions/32941064/gpg-hangs-on-entropy-generation
# for more on this topic.
python3 generate_secrets.py
```
