This repository contains Docker and other configuration files needed to run and deploy the autograder system.

# Dev Setup
See [this tutorial](./docs/development_setup.md).

# Production Setup (Non-Swarm)
See [this tutorial](./docs/production_non_swarm_setup.md).

# Production Setup (With Swarm)
See [this tutorial](./docs/swarm_deployment.md).

## Other Recipes and Things to Know
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

### Creating a Custom API Token
To create a custom api token, run the following in a django shell:
```
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

# Replace <username> with whatever you want.
user = User.objects.create(username='<username>@autograder.io')
token, created = Token.objects.get_or_create(user=user)
# If that username is taken, try another one.
assert created

# Securely share this token with whomever needs it.
print(token)
```

Add the username (`<username>@autograder.io`) to the appropriate roster for your course to give the token user the permissions it needs.

