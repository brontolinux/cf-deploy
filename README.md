# What is cf-deploy

cf-deploy was born when I worked in Opera software, where we had several projects that used CFEngine for configuration management, and all projects leveraged the same library of CFEngine bundles developed in house. We needed a decent way to deploy our CFEngine policies on a fleet of policy hubs scattered across several locations on the planet. Besides production hubs, we also had preprod, staging and all that.

In the beginning, we solved the problem through a makefile, which worked but was kind of inconvenient to use in many of the daily operations. We decided to create a front-end to that makefile, so that we didn't have to remember all those awkward `make` command lines: we wrote that front-end in bash and we called it cf-deploy. As the number of projects, environments and locations grew, managing the configurations for cf-deploy also started to become awkward, so we re-engineered the tool in Perl and around only two configuration files. That finally worked, and the tool was now flexible enough that it could be used to deploy more or less anything, as long as it fitted the case (a set of project-specific files merged with common libraries and deployed somewhere).

The previous releases of cf-deploy however carried with them the legacy of the environment they come from. For example, there was a number of settings and assumptions that made sense in the environment where the tool was born, but out of that environment they made the tool difficult to configure, or even unusable. Recently I had the need to use cf-deploy again to manage a personal project, and I decided to fix all those shortcomings. Welcome to cf-deploy v4.


# Installation

1. clone the repository in a directory (we'll call it `CFDEPLOY_TOOLDIR`)
2. copy or link `cf-deploy` in a directory in your path
3. create a projects database file (we'll call its path `CFDEPLOY_PROJDBFILE`), see instructions below
4. create a hub database file (we'll call its path `CFDEPLOY_HUBDBFILE`), see instructions below
5. set up your shell environment with the necessary configuration, see instructions below


# Configuration

cf-deploy is configured through shell environment variables. The names in the sections that follow refer to those variables.

## Project repositories

cf-deploy assumes that all the projects that it will manage are in subdirectories of a certain directory that we'll call `CFDEPLOY_GITDIR`. As you can tell from the name, cf-deploy was born in an environment where git was the version control system. Don't be fooled by the name however, you can use any VCS you like, as long as you also update the commands in the Makefile.

The common libraries that will be deployed with all projects are placed in a repository in a directory that we'll call `CFDEPLOY_COMMONDIR`. It can be placed anywhere you like, inside our outside `$CFDEPLOY_GITDIR`.

The (git) repository branch deployed by cf-deploy is, by default, `master`. You can set a different default branch by setting the variable `CFDEPLOY_BRANCH`.

## The projects database file (projects.db)

TBD

## The hub database file (hub.db)

TBD

## Changing the behaviour of cf-deploy

cf-deploy is just a front-end to a Makefile: cf-deploy rewrites your commands into make command lines, and make does the rest. You can customise what cf-deploy will do by modifying the commands ran by the targets in the makefile. E.g., if you want to deploy files in AWS S3 instead of a remote server, you can replace all the `rsync` commands in the makefile with the appropriate `aws s3` commands from the AWS CLI.

## Where cf-deploy is located

cf-deploy needs to know where the makefile and its configuration files are located:

* `CFDEPLOY_TOOLDIR` is the directory where the Makefile, and possibly cf-deploy itself, is located;
* by default, cf-deploy will look for the projects database file in `$CFDEPLOY_TOOLDIR/projects.db`; you can override this default by setting `CFDEPLOY_PROJDBFILE` to the full path of the file;
* by default, cf-deploy will look for the hub database file in `$CFDEPLOY_TOOLDIR/hub.db`; you can override this default by setting `CFDEPLOY_HUBDBFILE` to the full path of the file.

A sample for hub.db and projects.db is provided.


# Defaults

TBD

# Sample settings

```
CFDEPLOY_BRANCH=master
CFDEPLOY_COMMONDIR=/home/bronto/Lab/CMdata
CFDEPLOY_GITDIR=/home/bronto/Lab
CFDEPLOY_HUBDBFILE=/home/bronto/Lab/CMdata/services/files/cf-deploy/hub.db
CFDEPLOY_PROJDBFILE=/home/bronto/Lab/CMdata/services/files/cf-deploy/projects.db
CFDEPLOY_TOOLDIR=/home/bronto/Lab/cf-deploy
```

# Using cf-deploy

Just run the command without operands and it will tell you. This is what it returns on my laptop where it is linked in `/var/cfengine/bin`:

```
$ cf-deploy 

Usage:
  /var/cfengine/bin/cf-deploy PROJECT_NAME
    deploys project PROJECT_NAME on all hubs. It's a shortcut for
    /var/cfengine/bin/cf-deploy deploy PROJECT_NAME

  /var/cfengine/bin/cf-deploy deploy PROJECT_NAME [ branch BRANCH ] [ hub SERVER ]
    Deploys PROJECT_NAME with the specified options

  /var/cfengine/bin/cf-deploy preview PROJECT_NAME [ branch BRANCH ] [ hub SERVER ]
    preview the changes that would be applied

  /var/cfengine/bin/cf-deploy diff PROJECT_NAME hub SERVER [ branch BRANCH ]
    runs a diff for a project (hub is mandatory)

  /var/cfengine/bin/cf-deploy show PROJECT_NAME
    Describes the project PROJECT_NAME, other options are ignored

  /var/cfengine/bin/cf-deploy list projects
    Lists all defined projects, other options are ignored

  /var/cfengine/bin/cf-deploy list hubs
    Lists all but the test hubs (normally they are the one you are
    mostly interested in, but in case you are more curious...)

  /var/cfengine/bin/cf-deploy list all_hubs
    List absolutely all hubs, skipping none of them.

  You can override the default branch of a project by using the keyword
  branch. You can also override the project's hub list by specifying an
  hub with the hub keyword -- notice that specifying a hub for a local
  project is pointless

```

# References

If, for any reason, you want to know more about the story of cf-deploy and how it was born, you can check a blog post of mine, written in 2014: ["Git repository and deployment procedures for CFEngine policies"](http://syslog.me/2014/04/07/git-repository-and-deployment-procedures-for-cfengine-policies/). You can also take a look at the [slides of my presentation at Config Management Camp 2015](https://speakerdeck.com/brontolinux/many-projects-one-code).
