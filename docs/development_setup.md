# Development Stack Setup

This tutorial will walk you through installing and running the autograder on your local machine.

## System Requirements
**Supported Operating Systems:**
- Ubuntu 20.04 or later. Running on WSL should work in theory.

We don't officially support running on OSX, but in theory it should be possible.

## Install Docker Community Edition
Ubuntu: https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1

## Clone and checkout
```
git clone --recurse-submodules git@github.com:eecs-autograder/autograder-full-stack.git
cd autograder-full-stack
git checkout --recurse-submodules develop
git submodule update --remote --recursive
```
If you accidentally left out the `--recurse-submodules` flag, you can get the same effect by running this command in the autograder-full-stack directory:
```
git submodule update --init --recursive
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
- Changing the package.json file in ag-website-vue

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
Under the `nginx` block, change the `ports` option. For example, to change the port to 9001:
```
services:
  nginx:
    ...
    ports:
      - "4200:80"
    ...
```
Then, navigate to `localhost:9001` in your browser.

## "Authenticate"
By default, the development stack allows users to manually specify the user they wish to log in as.
The website only tries to automatically log the user in if a cookie called "token" is present.
If you are using the default fake authentication and this cookie is not present, **you will have to click the "Sign In" button every time you refresh the page**. To avoid this, use a browser plugin such as [EditThisCookie](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg?hl=en) for Google Chrome to create a cookie with "token" and any value.

To make the dev stack log you in as a specific user, set a cookie with key `username` and value `<desired username>`.
If the `username` cookie not is set, it will authenticate you as jameslp@umich.edu by default.
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
