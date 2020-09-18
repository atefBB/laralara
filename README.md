# laralara

Bash script to setup a fresh project using the latest versions of [Laravel](https://laravel.com)  and [Laradock](http://laradock.io).

## Introduction

I am old, and "Perl lazy", i.e., if I have to do the same thing more than once, I prefer to automate it as much as I can. Since I work with a lot of Laravel projects, writing this script became a labor of necessity. I hope you find it useful.  

I have attempted to write this script (and its accompanying documentation) to be as easily-understandable as possible, to assist new developers. That being said, this project does not attempt to "hold your hand"; under the [Assumptions](#assumptions) section, below, are links to the documentation for all of this project's dependencies. I will endeavor to assist you with issues directly related to the running and use of this script; I doubt I will have the time to assist beyond that.

## Overview

This script was originally written for use in Ubuntu 20.04 (actually, Ubuntu 20.04 via WSL2 on Windows 10). Theoretically, it should work on any Debian-based Linux distribution. 

This script does the following:

1. Creates a new project directory structure beneath wherever you define your `projects/` directory, with the name of your `--app-name` parameter value.  
2. Does a `git init` on the new project, and pulls in Laradock as a `git submodule`.  
3. Re-writes necessary configuration files for Docker Compose, MySql, and nginx; then saves copies for later re-use. (Sometimes, git submodules mysteriously disappear from your working copy; this ensures you don't lose your initial configurations.)  
4. Once the configuration files are re-written and copies saved, the script builds the containers.  
5. Once the containers are up and running, the script installs Laravel in the `workspace` container, installs all the Composer packages, and installs all the Node packages.  (And generates the initial Javascript files via Laravel Mix, too!)
6. Finally, the script does an itial commit of the newly-created project, as well as committing the changed files in the Laradock submodule.  

This script currently supports `mysql`, `redis` and `nginx` containers; if you need something more, you will need to con figure it yourself (if necessary -- a lot of laradock containers work as-is).

I should probably emphasize that all the files created by this script will reside inside your new project directory; you should never see any new files or directories inside *this* project afte running the `bin/laralara.sh` script.  

Once all that is done, refer to your git repository host for how to create a new repository from existing code.  

## Assumptions  
1. You are familiar with [Git](https://git-scm.com), or, at least [GitHub](https://github.com).
2. You are familiar with [Docker](https://www.docker.com).  
3. You are familiar with [Laravel](https://laravel.com).  
4. You are familiar with [Laradock](https://laradock.io).  
5. You know how to run a [Bash](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html) shell script.  

Support for this project will only focus on successfully running this script.  

## TODOs
-   As of this writing, this script has not been tested in a Mac environment -- if you're willing, please file issues so I can address them.  
-   Modify the script to run on either a Debian-based OR a Redhat-based distribution.  
-   Give the user the option to either install a specific version of Laravel OR checkout an existing laravel project from a `git` repository.  

## Installation  

1. Open a terminal and `cd` to the directory from which you want to run this script, typically a `projects` directory. (The script defaults to `${HOME}/Projects` but you can pass any path you want when you run the script).  
2. In your `projects` directory, run `git clone https://github.com/laidbackwebsage/laralara.git .`  
3. `cd laralara/` and run `bin/laralara.sh -h` to see how to use the script. (Or look at [Usage](#usage), below.)  

## Usage

A quick synopsis can be seen by running `bin/laralara.sh -h` from your local working copy. The results are:

```
This project can be download/clones from:
https://github.com/laidbackwebsage/laralara

Usage for bin/laralara.sh
===========================================================
-a, --app-name (required)
    This value will be appended to your "--project-dir"
    (q.v., below) to create the fully-qualified path to where
    your project will reside. If this path alreay exists,
    this script will fail with an error.

--mysql-version (optional)
    Set the mysql version to use; defaults to "latest".
    Valid values are: latest, 8.0.21, 8.0, 8, 5.7.31,
    5.7, 5, 5.6.49, 5.6

--php-version (optional)
    Set the php version to use; defaults to 7.4.
    Valid values are: 7.4, 7.3, 7.2, 7.1, 7.0, 5.6

-p, --project-dir (required)
    Fully-qualified path to your projects directory.
    Defaults to ${HOME}/Projects. If this path does not exist,
    it will be created.

-v, --verbose (optional)
    If passed on the command line, this script will output
    meaningful updates regarding what the script is doing.
    Otherwise, the script will remain silent, except for errors.

-w, --web-root-path (optional)
    Path to Laravel code in the workspace container, defaults
    '/var/www/<app-name>'

-h, -?, --help (optional)
    Displays this usage message and exits
```

Typical usage (accepting the defaults) would be: `bin/laralara.sh -v -a my-app-name`, substituting your own `app-name`, of course.  

Using all the command line parameters would look something like:  
`bin/laralara.sh -v -a my-app-name --mysql-version 8.0 --php-version 7.2 -p ${HOME}/my-projects --web-rout-path /my-laravel-code-path-in-container`  

**NOTE**: During the `build` events, you will see some warnings and errors; it is usually safe to ignore these, as long as the build process completes and the script doesn't exit prematurely.  

## Prerequisites

This script depends on `curl` and `html2text` being installed. To install them, open a terminal and run: `sudo update && sudo apt install -y curl html2text`. If either or both are already installed, running this command will do no harm.

If you run this script without either of these dependencies available, the script will notify you and exit gracefully. However, you will need to manually delete the newly-created project sub-directory; otherwise, the script will fail with:  
`ERROR: Your intended app path ... already exists.`

## Hosts File

One other thing you must do manually is add your new project's domain to your local `hosts` file. Your domain for local development will be the name of your app plus "`.test`". So, if your app name is `matilda`, your local domain would be `matilda.test`. To view your local site in your browser, you would go to: http://matilda.test. (NOTE: http://localhost/ may or may not work; the `.test` domain should ***always*** work...)  

If you don't know how to edit your `hosts` file, please refer to the instructions below:  

### Editing the `hosts` file

1. The first thing we need to do is find the `hosts` file and open in an editor as an Administrator (or, in Linux, `root`):  

    A. Windows

          i. Open your favorite text editor as an Administrator.  
         ii. In the address bar, type: C:\Windows\System32\drivers\etc.  
        iii. Look for the file named `hosts`. There maybe more than one file with the word `hosts` in it; you want the file labelled *only* `hosts`.  
         iv. Open it.

    B. Mac (FROM: [https://setapp.com/how-to/edit-mac-hosts-file](https://setapp.com/how-to/edit-mac-hosts-file))  

          i. Launch Terminal  
         ii. Type `sudo nano /etc/hosts` and press Return  
        iii. Enter your admin password  

    C. Linux  

          i. Open a terminal.  
         ii. Type `sudo nano /etc/hosts` and press Return  
        iii. Enter your admin password  

2. Once the file is open look for the last line that starts with a `#`.  
3. ***READ THIS SECTION CAREFULLY!!***  
    Beneath that line, look for a line that DOES NOT have a `#` and starts with: `127.0.0.1`. It is possible that you do not have such a line; in that case, you can add a new line below the last line that starts with `#`. (BUT KEEP READING...)  
  
    If your `hosts` file contains a line that starts with `# Added by `, DO NOT add anything to the lines below, even if there is a line that starts with `127.0.0.1` below it. Instead:  
        - If there is already a line that starts with `127.0.0.1` that is above the line that starts with `# Added by `, use *that* line.  
        - If there is *not* a line that starts with `127.0.0.1` that is above the line that starts with `# Added by `, typically, there is a block comment at the beginning of the file, i.e., several lines that start with `#`. Look for this comment block, and identify the last line in this block; this is where you will add a new line.
        
    Why not use a line that appears after a line that starts with `# Added by`? Because that section was added by another program, and that program can change whatever comes after that line. If that happens, you will use what ever changes you have made, and your local development project will no longer work in the browser until you repeat these steps in the `hosts` file.  

4. If your line already starts with `127.0.0.1`, go to the end of the line, add a space, then the name of your app's local domain; continuing our example from above, we would add `matilda.test`:  
    ```
    127.0.0.1   localhost matilda.test
    ```  
5. If you added a new line to the `hosts` file, just copy the full line from step number 4, replacing `matilda.test` with your own local domain. Note that there is a &lt;Tab&gt; character (not a space) after `127.0.0.1`. (If your editor doesn't like the tab, replace it with 4 spaces.)  
6. Save the file.  

Here is an example Windows 10 `hosts` file:  

```
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost
127.0.0.1 matilda.test

# Added by Docker Desktop
192.168.5.235 host.docker.internal
192.168.5.235 gateway.docker.internal
# To allow the same kube context to work on the host and the container:
127.0.0.1 kubernetes.docker.internal
# End of section

```

## About the newly-created project

You should be able to see your newly-created project in your browser at: `http://<your-app-name>.test`. 

I recommend using [Visual Studio Code](https://code.visualstudio.com) as an editor: it is available across multiple operating systems, and it's extensions ecosystem is pretty comprehensive.  

One of the reasons I recommend it is because of the [Remote - Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers). This extension allows you to attach to a running container via a terminal, or via the editor itself. Typically, I attach to the `workspace` container with the editor and edit my Laravel code there, instead of directly inside my project. (But that's my personal preference...)

If you go to your newly-created project in a terminal and type `code .`, Visual Studio Code should start inside the project's root folder; it should look something like this:  

```
<your-app-name>
    ├── app_src
    ├── bin
    ├── configs
    ├── docs
    ├── <your-app-name>-docker
    └── storage
```
-   `app_src` contains your Laravel code.  
-   `bin` is empty; future iterations of the Laralara project will copy new scripts here.  
-   `configs` contains copies of your initial configuration files.  
-   `docs` is empty; documentation for your new project should go here.  
-   `<your-app-name>-docker` contains all of Laradock's configuration files for everything that Laradock supports; it also contains the configuration files specific to your newly-created project that were generated by the `laralara.sh` script. (I.E., copies of the files stored in `configs`, above.)  
-   `storage` contains/will contain any bind volumes (as opposed to mount volumes) for your newly-created project's data containers. Currently, it only contains the Redis files; `mysql` is is a volume mount. Please refer to the Docker documentation regarding backing up and restoring volume mounts for the reasons why. (Hint: it is generally considered safer and easier to backup and restore volume mounts.)

## Contributing

Although I have used Git for a fairly long time, I am currently unfamiliar with how pull requests work. Once I get that under my belt (hopefully, soon), I will open up the project to contributrs. In the meantime, please feel free to file issues and feature requests, and I will get to them as I can.

## [Docker-clean](https://github.com/ZZROTDesign/docker-clean)  

I stumbled on this incredibly useful tool, and I recommend it to everyone using Docker, especially for local development.

I like to keep my working environment as pristine as possible, so I find `docker-clean all` to be extremely useful to revert to a clean environment before switching projects.  

On the other hand, while I'm working on a project, I don't like to re-pull images and rebuild custom containers unnecessarily; running `docker-clean -s -c --networks` cleans up everything very nicely.


