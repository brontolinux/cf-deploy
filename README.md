# cf-deploy v4

 **Welcome to cf-deploy v4**.
 
 ## A bit of history
 
 cf-deploy was born when I worked in Opera Software, where we had several projects that used CFEngine for configuration management and all projects leveraged the same library of CFEngine bundles developed in house. We needed a decent way to deploy our CFEngine policies on a fleet of policy hubs scattered across several locations on the planet. we had production, preproduction, staging and test hubs.

In the beginning, we solved the problem through a makefile, which worked but was kind of inconvenient to use in many of the daily operations. Thus we decided to create a front-end to that makefile, so that we didn't have to remember all those awkward `make` command lines: we wrote that front-end in bash and we called it cf-deploy. This worked for a while, but as the number of projects, environments and locations grew, managing the configurations for cf-deploy also started to become awkward, so we re-engineered the tool in Perl and around only two configuration files. That worked much better, and the tool was now flexible enough that it could be used to deploy more or less anything, as long as it fitted the case (a set of project-specific files merged with common libraries and deployed somewhere).

## Why a new version

The previous releases of cf-deploy however carried with them the legacy of the environment they came from. For example, there was a number of settings and assumptions that made sense in the environment where the tool was born, but out of that environment they made the tool difficult to configure, or even unusable. Unfortunately, I didn't notice how deep those assumption went and how bad they affected the tool, until recently. I decided to use cf-deploy again to manage a personal project and I hit those shortcomings myself, and decided to fix them.

One of the shortcomings was the documentation. I thought that the on-line help provided by the tool itself was enough, but as I rediscovered some features of the tool I had completely forgotten, I realised how bad and how incomplete the documentation was. Now, and for the first time, cf-deploy has a comprehensive documentation, which includes all the information needed to install and configure the tool and how you can tweak it. I don't know if it's enough, but I am quite sure it's a great improvement compared to what we had until v3.


# Installation

1. clone the repository in a directory (we'll call it `CFDEPLOY_TOOLDIR`)
2. copy or link `cf-deploy` in a directory in your path


# Configuration

The configuraton of cf-deploy is composed of:

1. the projects database file;
2. the hubs database file;
3. a set of environment variables defined in your shell

These three configuration components provide to cf-deploy the information about where your project repositories are, where the files shared by all projects are, and where they must be deployed.


## Project repositories

cf-deploy assumes that all the projects it manages are in subdirectories of a certain directory that we'll call `CFDEPLOY_GITDIR`. As you can tell from the name, cf-deploy was born in an environment where git was the version control system of choice. Don't be fooled by the name however, you can use any VCS you like, as long as you also update the commands in the Makefile.

The common libraries that will be deployed with all projects are placed in a directory that we'll call `CFDEPLOY_COMMONDIR`. It can be placed anywhere you like, inside our outside `$CFDEPLOY_GITDIR`. We recommend that you keep these files under version control, too.

 cf-deploy doesn't care if the content of `$CFDEPLOY_GITDIR` is a single repository or if each directory is a separate repository. If you want to manage all of your projects in a single repository, cf-deploy will only assume that each project is placed in a subdirectory; if you prefer to have separate repositories per project, you just need to clone the repositories for those projects in separate subdirectories under `$CFDEPLOY_GITDIR`.

The (git) repository branch deployed by cf-deploy is, by default, `master`. You can set a different default branch by setting the variable `CFDEPLOY_BRANCH`. You can also deploy specific branches by explicitly mentioning it on the command line.


## Configuration files

There are three files that govern the behaviour of cf-deploy. The *projects database file*, the *hub database file*, and the *Makefile* that runs the commands needed to deploy a project. The variable `CFDEPLOY_TOOLDIR` points to the directory where cf-deploy will find its Makefile. `$CFDEPLOY_TOOLDIR` will also be the default directory where the projects file and the hub file will be searched. If you want to place these two files somewhere else than the default location, and possibly give them a different name, you can do it by setting the variables `CFDEPLOY_PROJDBFILE` and `CFDEPLOY_HUBDBFILE` to the respective full paths of these files.

I suggest that you create a separate directory for these three files, and that they are source-controlled. Alternatively, if you wish to use the Makefile as is, you can set `$CFDEPLOY_TOOLDIR` to the same directory where you cloned the cf-deploy repository, and set `$CFDEPLOY_PROJDBFILE` and `$CFDEPLOY_HUBDBFILE` to other locations. This is because the cf-deploy repository carries two sample database files, and changing them locally will make it difficult to pull future updates of cf-deploy -- which is maybe why you wanted to use the Makefile from the repository clone in the first place: to make it easy to exploit updates to cf-deploy and its Makefile.


### The projects database file (projects.db)

The projects database file is a *CSV-like* file. Empty lines, or lines containing only whitespace, will be ignored. Lines beginning with a "#", possibly preceeded by whitespace, are considered comments and will also be ignored. Quotes don't have any special meaning.

Each line/record in the file has three fields separated by commas. The first field is the *name* of a project; the second field is the *directory* under `$CFDEPLOY_GITDIR` where the project is located; the third field is the *type* of the project: if the type is `remote`, then the project will be deployed on a remote machine; if the type is `local`, the project will be deployed in a local directory.

#### Examples

A line like:

```
myproj,    my,        remote
```

Will define a project called `myproj`. The files related to that project will be found in `$CFDEPLOY_GITDIR/my` and will be deployed to remote destinations defined in the hub database that is described in the next section.

Note: **dashes "`-`" have special meaning to cf-deploy in project names, please don't use them**; you are free to use underscores "`_`" though.

A line like:

```
home,      Private,   local
```

defines a project called `home`. The files related to that project will be found in `$CFDEPLOY_GITDIR/Private` and will be deployed to the local directory defined in the hub database that is described in the next section.


### The hub database file (hub.db)

The hub database file is a *CSV-like* file. Empty lines, or lines containing only whitespace, will be ignored. Lines beginning with a "#", possibly preceeded by whitespace, are considered comments and will also be ignored. Quotes don't have any special meaning.

What the hub database does is to connect the projects defined in the projects database with their hubs and where they are located in the case of remote projects. For local projects, the hub database connects projects with the directories where they should be deployed.

Each line/record in the file has four fields separated by commas:

* the *location* of the hub: it could be the name of a city, of a datacenter, of an AWS availability zone... or anything that makes sense to you and identifies where this piece of infrastructure is located, physically or logically; this information will be used when you want to do a deployment only in a specific location;
* the *project* owning this hub; the project must of course be defined in the projects database;
* the *environment* that is served by this hub; names like `prod`, `preprod` and `staging` are special to cf-deploy, as these are the environments that will be deployed by default if nothing else is specified; any other name that you will set for the environment of an hub (e.g.: `test`) will result in the hub not receiving updates by default, unless you explicitly deploy to that hub or that environment;
* the fourth field is an *identifier for the hub* that will receive your project; for remote projects, this will be a *hostname or an IP address*; for local projects, this will be a *directory*.

#### Examples

A set of lines like these:

```
Oslo,       myproj,   prod,        myproj-prod1.example.com
Oslo,       myproj,   preprod,     myproj-pre1.example.com
Amsterdam,  myproj,   test,        myproj-test.example.com
Amsterdam,  myproj,   prod,        myproj-prod2.example.com
Amsterdam,  myproj,   preprod,     myproj-pre2.example.com
```

defines the hubs for the project `myprod`. The projects spans two locations: Oslo and Amsterdam. It has one production and one preproduction hub in each location and, in addition, has a test hub in Amsterdam. When deploying the project, only the test hub in Amsterdam will be left out, unless explicitly requested.

This line:

```
Oslo,       home,     prod,        /etc/cfengine/test
```

sets for the local project `home`, located in Oslo, that it will be deployed in the directory `/etc/cfengine/test`.

## Environment varables and defaults

### `CFDEPLOY_GITDIR`

Directory under which the files for each project are located. Default: `/var/cfengine/git`

### `CFDEPLOY_TOOLDIR`

Directory where the Makefile, the projects database and the hub database are located. Default: `$CFDEPLOY_GITDIR/common/tools/deploy`

### `CFDEPLOY_COMMONDIR`

Directory where the common libraries, shared with all projects, are located. Default: `$CFDEPLOY_GITDIR/common`

### `CFDEPLOY_PROJDBFILE`

Full path of the project database file. Default: `$CFDEPLOY_TOOLDIR/projects.db`

### `CFDEPLOY_HUBDBFILE`

Full path of the hub database file. Default: `$CFDEPLOY_TOOLDIR/hub.db`

### `CFDEPLOY_BRANCH`

Branch deployed if none is specified. Default: `master`

### `CFDEPLOY_MASTERDIR`

For *remote* projects, this will be the directory on hubs in which your project will be deployed. **`CFDEPLOY_MASTERDIR` will be overridden by an environment variable `MASTERDIR` if it is set!**

For *local* projects, this variable will be ignored because the local directory where projects will be deployed is defined in the hubs database. For local projects, **the directory set in the hub database overrides the environment variable `MASTERDIR` if present!**

The default for this variable is `/var/cfengine/masterfiles`


# Fine tuning cf-deploy

cf-deploy is just a front-end to a Makefile: it gives you commands that are easy to remember and rewrites them into environment variables and `make` command lines, so that `make` knows how to do what you requested. You can customise what cf-deploy does by modifying the commands ran by the targets in the makefile or by setting environment variables, or both. E.g., if you want to deploy files in AWS S3 instead of a remote server, you can replace all the `rsync` commands in the makefile with the appropriate `aws s3` commands from the AWS CLI.


## Environment variables set by cf-deploy

cf-deploy sets some environment variables before running `make` to steer the behaviour of make. These variables are, in a way, the API of cf-deploy. Note that **if you set any of these variables manually, they will be overridden by cf-deploy**.

### `HUB_LIST`

A space-separated list of hubs where the project will be deployed.

### `PROJECT_NAME`

Name of the project to deploy.

### `PROJECT`

Name of the subdirectory where the project is located.

### `PROJECT_TYPE`

Type of the project: `remote` or `local`.

### `BRANCH`

Branch to be deployed.

### `LOCALDIR`

Directory under which the files for each project are located. Same value as `CFDEPLOY_GITDIR`.

### `COMMONDIR`

Directory where the common libraries, shared with all projects, are located. Same value as `CFDEPLOY_COMMONDIR`. 

### `MASTERDIR`

For remote projects, this variable will be set to the same value as `CFDEPLOY_MASTERDIR`, unless the variable is already set in the environment. If the variable is already set, its value will **not** be overridden. 

For local projects, cf-deploy will set this variable to the directory where the project will be deployed, overriding any value that you may have set otherwise.

### `SERVER`

Used with the `diff` command of cf-deploy. The command compares the files in the project with those present on the hub `$SERVER` and shows the differences.


## Environment variables used by the Makefile and not set by cf-deploy

There are more variables used in the Makefile that are **not** set by cf-deploy and will not be overridden by it. You can further refine the behaviour of cf-deploy by setting these variables.

### `RSYNC_USER`

When deploying via `rsync`, this will be the remote user used when connecting to the remote hub.

### `RSYNC_PREPARE_OPTS`

When deployng via `rsync`, these are the options that will be used, along with `RSYNC_COMMON_OPTS`, in the preparation phase, when the project files and the common files are copied in a temporary directory before they are then synchronised to their final destination.

### `RSYNC_REMOTE_OPTS`

Special options that will be used with `rsync` when synchronising a project to remote hubs, along with `RSYNC_COMMON_OPTS`.

### `RSYNC_COMMON_OPTS`

`rsync` options used for all operations, both for remote and local projects.

### `RSYNC_OPTS`

Basic options for `rsync`. This normally includes `RSYNC_PREPARE_OPTS`, `RSYNC_COMMON_OPTS`, and possibly something more.

### `DIFF_OPTS`

Options to use when diff-ing files with the `cf-deploy diff` command.

### `TMP_BASE`

Base directory for the temporary directories, used e.g. when project and common files are merged. Normally, `/var/tmp`.

### `TMP_TEMPLATE`

Template used with `mktemp` to build the name for a temporary directory where project and common files are merged.


# Using cf-deploy

This section illustrates the cf-deploy command line, and the `make` command run by each cf-deploy command

## cf-deploy

Run without arguments, cf-deploy shows the help page.

## cf-deploy *PROJECT_NAME*

Equivalent to `cf-deploy deploy` *`PROJECT_NAME`*

## cf-deploy deploy *PROJECT_NAME* [ branch *BRANCH* ] [ hub *SERVER* ]

Deploys project *PROJECT_NAME*. If *PROJECT_NAME* contains a dash (e.g.: `example-spec`) the name is split at the dash and the part on the right side (`spec` in this example) will be matched against the location and the environments to build the list of the hubs where the project will be deployed. E.g. if you run:

```
cf-deploy myproj-oslo
```

then your project `myproj` will be deployed only on the production/preproduction hubs that are located in Oslo.

If you run:

```
cf-deploy myproj-test
```

then your project `myproj` will be deployed on all the hubs in the `test` environment.

Note that **you cannot combine locations and environments in the same command**, you'll have to run separate commands. Note also that **you must avoid having locations that carry the same name as an environment** as the results may be at the very least confusing, and in the worst case tragic.

If `branch` is specified, it deploys the branch *BRANCH* instead of the default branch. If `hub` is specified, it will deploy only on the hub *HUB*.

`cf-deploy deploy` sets environment variables and then runs the following command for remote projects:

```make -e -C $CF_DEPLOY_TOOLDIR deploy```

and this command for local projects:

```make -e -C $CF_DEPLOY_TOOLDIR deploy_local```

## cf-deploy preview *PROJECT_NAME* [ branch *BRANCH* ] [ hub *SERVER* ]

Same syntax as `cf-deploy deploy`, but the `rsync` command will be run in *dry run* mode, showing which files would be updated if `cf-deploy deploy` is run but not actually synchronising files.

`cf-deploy preview` sets environment variables and then runs the following command for remote projects:

```make -e -C $CF_DEPLOY_TOOLDIR preview```

and this command for local projects:

```make -e -C $CF_DEPLOY_TOOLDIR preview_local```


## cf-deploy diff *PROJECT_NAME* hub *SERVER* [ branch *BRANCH* ]

Copies the project files for `PROJECT_NAME` from `SERVER` to a temporary directory, then deploys the project and common files into a second temporary directory, then runs a recursive `diff` on the two directories, showing you what will be changed if you deploy the project. Finally, cf-deploy cleans up the temporary directories.

If a different branch is not specified explicitly with the `branch` option, the default branch for the project will be used.

`cf-deploy diff` sets environment variables and then runs the following command for remote projects:

```make -e -C $CF_DEPLOY_TOOLDIR diff```

and this command for local projects:

```make -e -C $CF_DEPLOY_TOOLDIR diff_local```


## cf-deploy list projects

This command lists all the configured projects.

This is an internal command and doesn't activate any `make` target.

## cf-deploy show *PROJECT_NAME*

This command shows the configured settings for the project `PROJECT_NAME`.

This is an internal command and doesn't activate any `make` target.


## cf-deploy list hubs

This command lists all configured hubs for prod, preprod and staging for all projects.

This is an internal command and doesn't activate any `make` target.


## cf-deploy list all_hubs

This command lists all configured hubs for all projects, skipping none of them.

This is an internal command and doesn't activate any `make` target.

## Makefile targets not exercised by cf-deploy

The Makefile has a `distclean` target that can be used to clean up any temporary directory that was left over by cf-deploy, e.g. when the program was interrupted before it could clean up after itself.


# Sample settings

These are the settings I am currently using in a personal project of mine. All of my projects are kept in repositories under the directory `/home/bronto/Lab`; the makefile is in `/home/bronto/Lab/cf-deploy`, while the project and hub database files are in `/home/bronto/Lab/CMdata/services/files/cf-deploy`.

```
CFDEPLOY_BRANCH=master
CFDEPLOY_COMMONDIR=/home/bronto/Lab/CMdata
CFDEPLOY_GITDIR=/home/bronto/Lab
CFDEPLOY_HUBDBFILE=/home/bronto/Lab/CMdata/services/files/cf-deploy/hub.db
CFDEPLOY_PROJDBFILE=/home/bronto/Lab/CMdata/services/files/cf-deploy/projects.db
CFDEPLOY_TOOLDIR=/home/bronto/Lab/cf-deploy
```

# References

If, for any reason, you want to know more about the story of cf-deploy and how it was born, you can check a blog post of mine, written in 2014: ["Git repository and deployment procedures for CFEngine policies"](http://syslog.me/2014/04/07/git-repository-and-deployment-procedures-for-cfengine-policies/). You can also take a look at the [slides of my presentation at Config Management Camp 2015](https://speakerdeck.com/brontolinux/many-projects-one-code).
