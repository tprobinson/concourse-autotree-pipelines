# Concourse Autotree pattern

This repository is an scaffold for laying out Concourse Pipelines.

The layout and included script are intended to make automating based on the Concourse pipelines easy.

<!-- MDTOC maxdepth:6 firsth1:1 numbering:0 flatten:0 bullets:1 updateOnSave:1 -->

- [Concourse Autotree pattern](#Concourse-Autotree-pattern)   
- [Getting started](#Getting-started)   
   - [Pipeline Structure](#Pipeline-Structure)   
      - [Standalone Pipelines](#Standalone-Pipelines)   
      - [Variant Pipelines](#Variant-Pipelines)   
      - [Disabling a Pipeline](#Disabling-a-Pipeline)   
   - [Using the `update-all` script](#Using-the-update-all-script)   
      - [Prerequisites](#Prerequisites)   
      - [Running the Script](#Running-the-Script)   
- [Other automation that uses this pattern](#Other-automation-that-uses-this-pattern)   
- [Known Issues / TODO](#Known-Issues-TODO)   

<!-- /MDTOC -->

# Getting started

The `teams` folder has sub-folders named according to each team. Below that, each pipeline has its own folder. In each folder, a YAML file named like `<pipeline name>.yml` is used as the base for that pipeline.

Any variables that are common among many pipelines can be put into `common-vars.yml`, while any sensitive variables like passwords, SSH private keys, certificates, should be kept in `credentials.yml`. The credentials file is ignored in this repository, so an example can be found at `credentials_example.yml`.

Any other files and folders at the top level of this repository are ignored, so you can use it as a source for common tasks in pipelines if you want.

## Pipeline Structure

There are two types of pipelines recognized in this repository.

### Standalone Pipelines

Standalone pipelines are a simple, basic pipeline. They consist of only a single `.yml` file. The file's name will be the pipeline's name in Concourse.

This pipeline will receive the `common-vars.yml` file and the `credentials.yml` file. Use these variables with Concourse's builtin `((variable_name))` syntax.

An example of this layout is at `teams/admin/container-alpine`. This example would create a `container-alpine` pipeline in the `admin` team.


### Variant Pipelines

Variant pipelines create several pipelines off of one base `.yml` file. They have one main `.yml` file and a folder called `variants`. Inside that folder should be one or more `.yml` files that contain variables to fill into the base pipeline file.

This pipeline will receive each variant file one at a time, the `common-vars.yml` file and the `credentials.yml` file. Use these variables with Concourse's builtin `((variable_name))` syntax.

An example of this layout is at `teams/dev/our-web`. This example would create `our-web-prod`, `our-web-stage`, and `our-web-test` pipelines in the `dev` team, each with different variables.

In this example:
`our-web-prod` would be created with `tag_filter: release-*`
`our-web-stage` would be created with `tag_filter: RC-*`
`our-web-test` would be created with `tag_filter: ''`


### Disabling a Pipeline

To keep a pipeline from being touched by the update-all script, create a file called `disabled` in its repository.

An example of this is at `teams/admin/container-experimental`.

## Using the `update-all` script

### Prerequisites

The script was originally written for the [Fish shell](https://fishshell.com). A Bash translation has been provided, but might not be kept up to date. It's recommended you install Fish if possible.

The script runs through each team, then through each pipeline, setting each one in Concourse using the `fly` CLI tool. Make sure this is installed on the machine you're running it on.

Create a file called `fly_team_authentications.fish` (or `.bash` if you're using the Bash script). In this file, create a username and password variable for each team in this repository.

The username and password should correspond with what ever you set the "Basic Auth" credentials for that team to be.

For example, with this repository, we have the admin, automation, and dev teams. So we'd create the following variables:

```sh
set admin_username admin
set admin_password whatever

set automation_username automation
set automation_password somethingelse

set dev_username dev
set dev_password blahblahblah
```

Then add one more variable to point to your concourse instance: `concourse_url`:
```sh
set concourse_url https://internal.concourse.instance.example.com
```

This file is also ignored in Git, so you don't commit credentials into source control.

### Running the Script

**Warning:** The script does not ask you if you want to commit any changes, it just assumes 'yes' to everything. Good for those who want the repository to be treated as a declarative state for Concourse.

```sh
# git fetch; and git reset --hard origin/master; and fish update-all.fish
Logging in to team admin: done
container-alpine: done
container-experimental: disabled
Logging in to team automation: done
random-task: done
Logging in to team dev: done
our-web:
  our-web-prod
  our-web-stage
  our-web-test
Done!
```

# Other automation that uses this pattern

*Coming soon*

You could make a pipeline triggered on a webhook from your autotree repository that runs update-all, if you want it to be totally automatic.

# Known Issues / TODO

Only the .yml extension is recognized currently. If possible, .yaml should be supported as well.
