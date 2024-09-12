This repository contains Docker and other configuration files needed to run and deploy the autograder system.

# Announcements
- Aug 26, 2024: Release 2024.08.v0 is out. See https://github.com/orgs/eecs-autograder/projects/2/views/1 for a list of addressed issues.
    - Changes to the "Upgrading (Production Deployments)" section of this document regarding upgrade requirements.
    - autograder-server and ag-website-vue submodules now use calendar versioning.

# Versioning
As of Jan. 2021, we use the following version scheme for release tags in this repo (autograder-full-stack):
```
{yyyy}.{mm}.v{X}
```
- `{yyyy}` is the year of the release (e.g. "2021").
- `{mm}` is the month of the release (e.g. 01, 06, 08, 09 for Jan, June, Aug, or Sept).
- `{X}` is the minor version number, incremented for smaller changes (patches, bug fixes) between major releases.

(Written on Aug. 23, 2024): Starting with our next release, we will start using this calendar versioning scheme for
the autograder-server and ag-website-vue sub-repositories. Note that since npm doesn't allow the "v" in the minor 
version portion, we will omit it in the package.json file in that repository. We will also omit the "v" in 
autograder-server for symmetry. These version labels will be synchronized (i.e., the submodules will have the same
version as this repo's release tags) to make it easier to verify that the deployed repos are in sync.
ag-client-typescript will continue to use semantic versioning.

# Dev Setup
See [this tutorial](./docs/development_setup.md).

# Swarm Production Setup
See [this tutorial](./docs/swarm_deployment.md).

# Single-server Production Setup
See [this tutorial](./docs/production_non_swarm_setup.md).

# Upgrading (Production Deployments)
To upgrade from one major version to the next, follow these steps:

1. Pull the `master` branch in the `autograder-full-stack` repo and pull the latest tags.
    ```
    cd autograder-full-stack
    git checkout master
    git pull
    git pull --tags
    ```

2. Checkout the tag for the version you want to upgrade to.
    ```
    # Replace {tag} with the appropriate version (e.g. 2021.01.v3)
    git checkout {tag}
    ```
    **Legacy Note**: If your deployment is behind by several _major_ versions (the {yyyy}.{mm} portion of the version number), we recommend **upgrading to each intermediate major version sequentially**. This is important to ensure that database migrations run correctly.

   **Updated Note**: **Starting with release 2024.08.v0**, we will generally try to make it possible to upgrade from 2024.08.v0 straight to the newest version without upgrading to each intermediate version. If a release requires upgrading from a specific previous version, we will note this requirement in the announcements section of this document.

4. Update the `autograder-server` and `ag-website-vue` submodules. If you've made changes to the submodules (such as changing config settings), you may need to stash them first and then re-apply. Git will warn you if you need to do so.
    ```
    git submodule update --remote
    ```

5. Re-deploy the docker containers and apply database migrations. This step varies slightly depending on which deployment strategy you're using (e.g., single server, swarm). Please refer to the appropriate tutorial for the specific commands: [swarm](./docs/swarm_deployment.md),
[single server](./docs/production_non_swarm_setup.md).

## Website UI Documentation
Documentation on how to configure projects, test cases, and more through the web interface can be found at
https://eecs-autograder.github.io/autograder.io/

## Other Recipes and Things to Know
### Useful scripts
If you want to automate a task using a scripting language, you can use the Python HTTP client found at 
https://github.com/eecs-autograder/autograder-contrib and some ready-to-use python scripts at https://gitlab.eecs.umich.edu/akamil/autograder-tools.
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
This is now possible through the UI.
See https://eecs-autograder.github.io/autograder.io/how_tos.html#rerunning-a-stuck-or-errored-submission

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

