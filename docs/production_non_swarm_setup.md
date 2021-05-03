# Single-server Production Setup

## First Steps
Follow the instructions in [this tutorial](./production_first_steps.md) to set
up your server.

## Other Tweaks
* In `docker-compose-single.yml`, adjust the value of the `--workers=xx` flag
  to set the number of gunicorn workers.
    * NOTE: For a single-server deployment, you should be conservative with this value or
      remove the flag to use gunicorn's default behavior.
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
* (Optional) Adjust the number of grader workers in `docker-compose-single.yml`:
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

    # Uncomment this block in docker-compose-single.yml if you want to enable
    # the "fast" queue. This provides a dedicated worker for submissions
    # with a short estimated grading time.
    fast_grader:
      command: /usr/local/bin/celery -A autograder worker -n fast_submission_grader@%h --loglevel=info -c 1
    ```

## Run the Production Stack
```
docker-compose -f docker-compose-single.yml build
docker-compose -f docker-compose-single.yml up -d
```

To update the containers:
```
docker-compose -f docker-compose-single.yml stop
docker-compose -f docker-compose-single.yml build
docker-compose -f docker-compose-single.yml up -d
```

This repo also provides the script `compose-single` as an alias for
`docker-compose -f docker-compose-single.yml`:
```
./compose-single build
./compose-single up -d
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
