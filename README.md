This repository contains Docker and other configuration files needed to run and deploy the autograder system.

# Announcements
- Aug 26, 2024: Release 2024.08.v0 is out. See https://github.com/orgs/eecs-autograder/projects/2/views/1 for a list of addressed issues.
    - Changes to the "Upgrading (Production Deployments)" section of this document regarding upgrade requirements.
    - autograder-server and ag-website-vue submodules now use calendar versioning.

# Website UI Documentation
Documentation on how to configure projects, test cases, and more through the web interface can be found at
https://eecs-autograder.github.io/autograder.io/

# Versioning

## Versioning Convention Updates

### August 2025 - present
We continue to use calendar versioning, but we remove the `v` from the version number in previous versions:
```
{yyyy}.{mm}.{minor version}.{pre-release modifier}
```
We generally follow [Python conventions](https://packaging.python.org/en/latest/discussions/versioning/)
E.g., our next major release at time of writing will be `2025.08.0`.

`ag-client-typescript` now also uses calendar versioning.

### Jan. 2021 - July 2025
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

# Installation/Setup & Upgrading

## Dev Setup
See [this tutorial](./docs/development_setup.md).

## Swarm Production Setup
See [this tutorial](./docs/swarm_deployment.md).

## Single-server Production Setup
See [this tutorial](./docs/production_non_swarm_setup.md).

## Upgrading (Production Deployments)
We typically only release updates to the latest calendar version (e.g., `2025.08.x`).
In the case of a critical issue, we may decide to backport certain updates to prior versions.

### Upgrading to 2025.08.0 or Later

### Upgrading to 2024.08.v0 or Earlier
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

# Other Recipes and Things to Know
## Useful scripts
If you want to automate a task using a scripting language, you can use the Python HTTP client found at
https://github.com/eecs-autograder/autograder-contrib and some ready-to-use python scripts at https://gitlab.eecs.umich.edu/akamil/autograder-tools.
  * IMPORTANT: Make sure to use the correct URL for your deployment. In the former set of scripts, this is configurable with command-line arguments. In the latter, you may need to modify the source code.

## Giving a user permission to create courses
Run the following in a django shell (`docker exec -it ag-django python3 manage.py shell`):
```
from django.contrib.auth.models import User, Permission
# UPDATE the email address
user = User.objects.get(username='@umich.edu')
user.user_permissions.add(Permission.objects.get(codename='create_course'))
```

## Submissions not being processed for one project
This issue should be fixed as of `2024.08.0`.
Notes on how to resolve are below just in case.

Occasionally a new project won't be correctly registered with the grading workers, and so submissions won't get past "queued" status. To manually register the project, run the following in a django shell:
```
from autograder.grading_tasks.tasks import register_project_queues
# UPDATE the project_pks list. The project primary key can be found in the url when viewing the project on the website.
register_project_queues(project_pks=[339])
```

## Submission(s) stuck at "being graded" status
This is now possible to resolve through the UI.
See https://eecs-autograder.github.io/autograder.io/how_tos.html#rerunning-a-stuck-or-errored-submission

## Creating a Custom API Token
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

# Development & Release Branches: Protocols and Workflow
This section is intended for developers.

### "master" branch
The `master` branch points to the latest release.
**As of 2025.08.0**: Do not make feature/fix PRs against this branch.
It should only be modified to point to the latest release.

### "develop" branch
Use feature branches for all changes, and make a pull request against the `develop` branch.

This repo has two submodules: `autograder-server` and `ag-website-vue`.
The `develop` branch is for changes based on the `develop` branch of the submodules.
Update the submodules' `develop` branches when preparing a release or when starting work on a feature that depends on new `autograder-server` or `ag-website-vue` commits.
Use the following steps on your feature branch:
```
# Fetch latest submodule commits
git submodule update --remote
# git status should show new commits in the submodule
git status
git add autograder-server ag-client-typescript
git commit -m "Update submodules"
```

### "release-*" branches
Name release branches as `release-YYYY.MM.x`, replacing YYYY with the full year and MM with the zero padded month (e.g., `release-2024.08.x`).

**IMPORTANT**: When you create a release branch, update the `branch` field in the `autograder-server` and `ag-client-typescript` entries of `.gitmodules` to point to the corresponding release branch in the submodules.
Then run `git submodule update --remote` and commit the changes.

Do NOT merge or rebase directly between the develop and release branches.
Once a release branch is created, it should only be updated with bugfix- or (rarely) feature-style branches.
Squash-and-merge for this type of PR.
After the squashed branch is merged into a release branch, cherry-pick the squashed commit on top of `develop` and open a pull request to merge the changes into `develop`.

The version of `README.md` (this file) on the `develop` branch is the source of truth.
Update this file on release branches just before publishing a release.
If instructions differ across releases, include both, and label which version the instructions apply to.

### Publishing a release
To create a github release, trigger a `workflow_dispatch` event on the release branch.
Pass the version number as input.

CI will tag the release, and create a GitHub release.
