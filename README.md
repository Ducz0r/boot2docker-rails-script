## Boot2Docker & Ruby on Rails Windows Script

The purpose of this script is to slightly easen the _Ruby on Rails_ development process on Windows computers when using _Docker_.

_Docker_, in a way, propagates itself as a method to allow cross-platforms developers to work on a shared project that's executed in the same virtual space throughout different host operating systems. 

If the host operating system is, _Windows_, however, by following the standard _Docker_ way of doing things, development & running of _Ruby on Rails_ project is excrutiatingly slow. I wrote this script to somewhat speed that process up. 

The script partially replaces the commonly used **docker compose** scripting system used by _Docker_ users on Linux & Mac OS platforms.

## How does it work?

### Problem

On _Windows_ operating systems, Docker runs in a special [VirtualBox](virtualbox.org/) Linux virtual machine called **boot2docker**. This machine has specific shared file system with the host _Windows_ system, and this filesystem share is the problem for the poor performance whenever you want to execute your _Rails_ application directly from the _Docker_ image.

The way user would normally setup his development environment on _Windows_ would be to have a _Ruby on Rails_ project folder on a Windows host, and then execute _Rails_ server inside the _Docker_ container **inside the same project folder**. For that approach to work, user must mount his _Windows_ project folder inside the _Docker_ container. And that is the reason for poor performance.

To access host _Windows_ OS file system, _boot2docker_ uses _VirtualBox_'s own filesystem called **vboxfs**. This virtual file system is great because it works across different OS platforms, but is very slow when it comes to actually using it real-time. On Mac OS systems, there exists solution around this (see [Hodor](https://github.com/gansbrest/hodor)), but on _Windows_, there is no common alternative.

### Solution

This script first starts the regular _Docker_ container (inside _boot2docker_ virtual machine) using _vboxfs_ file system to mount your _rails_ project folder inside virtual machine. Then, once inside _Docker_ container, it copies the folder onto a virtual folder existing only inside the container, and sets up file synchronization between the two folders. User then operates only on the "mirrored" folder from inside the container, which is much faster than the regular way (you can also use that command by running `wmake.sh cli nosync`). Both folders are synchronized each second, and the synchronization obviously works both ways.

### Tradeoffs

Of course, having to copy the entire project directory structure means that starting up the _Docker_ container (or _Rails_ server) takes more time than it would the normal way. The performance gain after that's done, though, is staggering. On a _Rails_ project I'm currently using this script (~93MB), it takes additional 5-10 seconds to start, but performance gain when running `rails server`, `rake generate`, `rake test` and many other commands, is 7-10-times faster.

## Prerequisites

- [Boot2Docker](http://boot2docker.io/) installed on the host Windows OS,
- [MinGW](http://www.mingw.org/) installed & configured on the host Windows OS,
- Configured _Dockerfile_ inside your _RoR_ project folder. The Linux image used for the _Docker_ container can probably be any Linux container, but this script was configured to work with Debian packages. The _Dockerfile_ should also include some specifics that are neccesary for the **wmake.sh** to work.
	- The following 2 packages need to be installed on the container image: [sudo](http://www.sudo.ws/), [unison](http://www.cis.upenn.edu/~bcpierce/unison/). On Debian, you can do that with the following _Dockerfile_ instruction: `RUN apt-get install -y unison sudo`.
	- The user that will be running inside the container image must be a member of the _sudoers_ group and have no sudo password requirement set. On Debian, the following _Dockerfile_ instruction does exactly that:
		```
		RUN useradd -ms /bin/bash -G sudo <user>
		RUN echo "<user> ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
		USER <user>
		```
## Usage

Open the script file `wmake.sh` in your favourite text editor and setup the variables depending on your host system. Then run `wmake.sh help` to see all options and their explanations.

## Warning
This script is NOT 100% tested and might need additional furnishing. It works nicely on my _Windows 8_ system for a relatively lightweight _Ruby on Rails_ web app.

## Troubleshooting

- If you see temporary files in your project folder (from Windows host), following approaches might work:
  - unmark your project folder (and subfolders) on Windows host as read-only. 
