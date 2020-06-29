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
