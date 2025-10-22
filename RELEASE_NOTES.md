# Version 2025.08.1 Release Notes

IMPORTANT: if upgrading to this release from 2024.08 or earlier, follow the
[upgrading guide from the 2025.08.0 release notes](https://github.com/eecs-autograder/autograder-full-stack/releases/tag/2025.08.0).

## Changelog
A full list of issues and pull requests included in this release can be found [here](https://github.com/orgs/eecs-autograder/projects/3).

#### Fixed
- Fixed a bug where loading mutation suite buggy implementation output caused an
  error in some cases (autograder-server #728)
- Fixed a bug in group registration. Input validation when sending a group
  invitation now correctly checks the minimum group size when the minimum is
  two or greater (ag-website-vue #559)

# Version 2025.08.0 Release Notes

## Changelog
A full list of issues and pull requests included in this release can be found [here](https://github.com/orgs/eecs-autograder/projects/3).

### User facing changes
#### Added
- Added custom scoring functionality, allowing instructors to assign
  test case scores by printing the score to stdout or stderr (#62)
- Implemented a [command-line + YML schema interface](https://github.com/eecs-autograder/autograder-cli) for editing project settings. Notable features include:
  - Downloading existing projects and saving the configuration to a YML file
  - Creating or saving a project from the command line using a YML file
  - VSCode support for linting/autocmplete in the YML file.

#### Changed
- Changed test case settings UI to better differentiate between different
  scoring mechanisms (ag-website-vue #540)

#### Fixed
- Fixed an issue where Mutation testing hints would not be copied when
  duplicating a course (#64)
- Fixed some accessibility issues with modal UI elements (ag-website-vue #532)
- Fixed some accessibility issues with button UI elements and keyboard
  interactions(ag-website-vue #533)
- Fixed a bug related to an uncommon combination of feedback settings.
  When correctness for command checks (e.g., stdout or return code correctness)
  was shown, points for those individual checks would be present in the API
  response even if the "show points" setting was false. (autograder-server #706)
- Fixed a bug where the wrong duration until the deadline would be shown when
  calculated across certain months (ag-website-vue #536)

#### Removed
- Removed support for `StdinSource.setup_stdout` and `StdinSource.setup_stderr`

### Dev and sysadmin facing changes
#### Added
- Updated link in API docs to download personal access token to be relative to
  the current domain (autograder-server #711)
- Added a LateDayUsage database model to log information about each submission
  that uses a late day. This will be used in the future to make it easier to
  refund late days when a deadline is pushed back (autograder-server #715)
- Added new "validated input" logic and components that use the Composition API
  for future compatibility and flexibility (ag-website-vue #534)
- Added build:clean npm script for idemponent builds (ag-client-typescript #167)
- Added end-to-end testing using Playwright (ag-website-vue #529)

#### Changed
- Optimized file storage for output files produced when grading submissions
  (autograder-server #714) (autograder-server #710)
- Updated Django 3->5, Psycopg 2->3, and Postgres 13->14 (autograder-server #720)
- Changed frontend unit test runner from Jest to Vitest (ag-website-vue #528)
- Updated autograder-sandbox library to version 6.0.0

## Upgrading from version 2024.08

There are several important changes to consider when upgrading your deployment
of autograder.io. The first is that starting with this version, Postgres 14 is
required. Along with this, there's been a change in how we specify the Postgres
version in the build stage. Secondly, we've changed how many files are stored
to reduce the storage overhead required for submissions. This will require
migrating old submission data to the new format.

Below is an outline of the steps required to upgrade:
1. Schedule maintenance downtime
1. If not already running 2024.08.0 (the prior major release), update to that
   version now
1. Pause or stop the grading workers
   - For a single server deployment, use `docker pause <grading containers>`
   - For a swarm deployment, either use `docker pause <grading containers>` on
     the machines running those containers, or remove the grading worker
     labels from the nodes
1. Upgrade Postgres to version 14. See [](https://github.com/eecs-autograder/autograder-full-stack/blob/develop/README.md#upgrading-postgres)
   for the necessary steps, including how to specify the new version.
1. Update the source code to 2025.08.0. See [](https://github.com/eecs-autograder/autograder-full-stack/blob/develop/docs/production_first_steps.md#updating-the-source-code).
   You can use the tag `latest` to specify this version
1. Run the updated stack:
   - For single server deployments, see [](https://github.com/eecs-autograder/autograder-full-stack/blob/develop/docs/production_non_swarm_setup.md#run-the-production-stack)
   - For swarm deployments, see [](https://github.com/eecs-autograder/autograder-full-stack/blob/develop/docs/swarm_deployment.md#build-and-deploy-the-stack)
1. Apply database migrations on the node running the API
   - For single server deployments, see [](https://github.com/eecs-autograder/autograder-full-stack/blob/develop/docs/production_non_swarm_setup.md#finish-setting-up-the-database)
   - For swarm deployments, see [](https://github.com/eecs-autograder/autograder-full-stack/blob/develop/docs/swarm_deployment.md#finish-setting-up-the-database)
1. Run the output migration script. If your deployment has a lot of submissions,
   this can take a while. While there should be no problem letting this script
   run while your deployment is active and being used, there can potentially be
   problems if an old submissions is re-run while that submission is being
   migrated. To reduce the already low possibility of this occurring, we suggest
   first migrating recent submissions before starting to migrate the rest and
   deploying the new changes
   - First check how many submissions that were made since yesterday need to be
     migrated: `docker exec -it ag-django python3 manage.py migrate_output --since <yesterday> --summarize`
   - Migrate those submissions and wait until the script finishes (within reason)
     before continuing: `docker exec -it ag-django python3 manage.py migrate_output --since <yesterday>`
   - Migrate the rest of the submissions. No need to wait until this finishes
     continuing: `docker exec -it ag-django python3 manage.py migrate_output --until <yesterday>`
