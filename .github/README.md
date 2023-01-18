# ans_bootstrap_run_playbook

Shell script to bootstrap ansible and playbook dependencies, and run playbook.

[![Release](https://img.shields.io/github/release/digimokan/ans_bootstrap_run_playbook.svg?label=release)](https://github.com/digimokan/ans_bootstrap_run_playbook/releases/latest "Latest Release Notes")
[![License](https://img.shields.io/badge/license-MIT-blue.svg?label=license)](LICENSE.txt "Project License")

## Table Of Contents

* [Purpose](#purpose)
* [Quick Start](#quick-start)
    * [Configure A Git Playbook Repo To Use This Script](#configure-a-git-playbook-repo-to-use-this-script)
    * [Update Git Playbook Repo With Script Changes](#update-git-playbook-repo-with-script-changes)
* [Full Usage / Options](#full-usage--options)
* [Examples](#examples)
* [Contributing](#contributing)

## Purpose


* Install ansible, python, and any ansible dependencies needed by a playbook.
* Fetch and update all roles used by a playbook.
* Run the playbook.

## Quick Start

### Configure A Git Playbook Repo To Use This Script

These instructions assume that you have a git repo that hosts an ansible
playbook. The steps below add ans_bootstrap_run_playbook as a third-party git
submodule in the playbook repo.

1. Change to the playbook repo directory:

   ```shell
   $ cd my_playbook_repo
   ```

2. Add ans_bootstrap_run_playbook as a submodule of my_playbook_repo:

   ```shell
   $ git submodule add https://github.com/digimokan/ans_bootstrap_run_playbook.git \
     third_party/ans_bootstrap_run_playbook
   ```

3. Commit the new submodule as a commit in my_playbook_repo:

   ```shell
   $ git add .
   $ git commit
   ```

### Update Git Playbook Repo With Script Changes

After changes are committed to ans_bootstrap_run_playbook, update
my_playbook_repo to use the changes.

1. Change to the playbook repo directory:

   ```shell
   $ cd my_playbook_repo
   ```

2. Get all recent ans_bootstrap_run_playbook changes:

   ```shell
   $ git submodule update --remote
   ```

3. Commit submodule changes as a commit in my_playbook_repo:

   ```shell
   $ git add .
   $ git commit
   ```

## Full Usage / Options

```
USAGE:
  make_archiso_zfs.sh        -h
  sudo  make_archiso_zfs.sh  -b  [-c]  [-z]  [-p <pkg1,pkg2,...>]  [-P <pkgs_file>]
                             [-f <file1,dir1,...>]
                             [-w <device>]
  sudo  make_archiso_zfs.sh  -w <device>
OPTIONS:
  -h, --help
      print this help message
  -b, --build-iso
      build base iso running stock Arch 'linux' kernel pkg
  -z, --enable-zfs-kernel-module
      add 'archzfs-linux' stable kernel mod, enable it at boot
  -p <pkg1,pkg2,...>, --extra-packages=<pkg1,pkg2,...>
      extra packages to install to iso
  -P <pkgs_file>, --extra-packages-file=<pkgs_file>
      extra packages to install to iso (from file, one pkg per line)
  -f <file1,dir1,...>, --user-files=<file1,dir1,...>
      add files and directories to iso (in '/root/' dir)
  -w <device>, --write-iso-to-device=<device>
      write built iso to device (e.g. device /dev/sdb)
EXIT CODES:
    0  ok
    1  usage, arguments, or options error
    5  archiso build error
   10  archiso write-to-device error
  255  unknown error
```

## Examples

* Build archiso running stable zfs kernel module:

   ```shell
   $ sudo ./make-archiso-zfs.sh -bz
   ```

* Build archiso with stock Arch Linux kernel (no zfs kernel modules):

   ```shell
   $ sudo ./make-archiso-zfs.sh -b
   ```

* Build archiso and install additional packages to iso:

   ```shell
   $ sudo ./make-archiso-zfs.sh -bz -p "git,ansible"
   ```

* Build archiso and add a file to the iso `/root/` directory:

   ```shell
   $ sudo ./make-archiso-zfs.sh -bz -f "my_custom_script.sh"
   ```

* Build archiso and write the built iso to a USB drive:

   ```shell
   $ sudo ./make-archiso-zfs.sh -bz -w /dev/sdb
   ```

* Write iso (from `./out/archlinux-*.iso`) to USB drive:

   ```shell
   $ sudo ./make-archiso-zfs.sh -w /dev/sdb
   ```

* Build archiso and write to USB drive using alternate long options:

   ```shell
   $ sudo ./make-archiso-zfs.sh --build-iso --enable-zfs-kernel-module --write-iso-to-device=/dev/sdb
   ```

## Contributing

* Feel free to report a bug or propose a feature by opening a new
  [Issue](https://github.com/digimokan/ans_bootstrap_run_playbook/issues).
* Follow the project's [Contributing](CONTRIBUTING.md) guidelines.
* Respect the project's [Code Of Conduct](CODE_OF_CONDUCT.md).

