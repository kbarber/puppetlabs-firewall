Vagrant Image Maintenance
=========================

[TOC]

Introduction
------------

This document describes how you can recreate the images that are currently
hosted on the Internet from scratch. I've used veewee definitions to create
them so it should be clear enough to replicate them.

This document is also useful for those who wish to create new acceptance
host images using other OS, or updated OS.

Building Images from Scratch
----------------------------

The test environment requires a number of images of different kinds for running
tests. I've chosen to use Vagrant to build these, since the methodology to
reproduce them is stored in code.

### Prerequisites

My environment before I started:

*   Mac OS X 11.8.0
*   VirtualBox 4.1.18-78361
*   git 1.7.11.3
*   rvm 1.14.10

### Grab the code

Grab the firewall code:

    (from your dev dir ...)
    git clone git://github.com/puppetlabs/puppetlabs-firewall.git

### Prepare your environment

    cd puppetlabs-firewall/acceptance/vagrant

At this point if you are running a relatively new version of RVM, you should
find your Ruby version and gemset change, otherwise do this:

    rvm install ruby-1.9.3
    rvm gemset create puppetlabs-firewall-vagrant
    rvm use ruby-1.9.3@puppetlabs-firewall-vagrant

Then run bundler to grab the necessary bits:

    bundle install

### Build boxes using veewee

Now we need to create some vagrant boxes. I use veewee for this as its totally
reproducable from code/config. I borrowed heavily from the
[veewee docs for vagrant][1] so if you get lost check those docs.

    veewee vbox define 'centos-58-64bit' 'CentOS-5.8-x86_64-netboot'
    veewee vbox build 'centos-58-64bit'

Now you need to wait ... say 'Yes' to download the image, and say 'Allow' to
VirtualBox if it asks about firewalling.

Now wait some more ... you should see the image slowly build.

    veewee vbox validate 'centos-58-64bit'

Now we want to export it for vagrant to use:

    vagrant basebox export 'centos-58-64bit'

You should at that point have a file 'centos-58-64bit.box' in the current
directory.

You can test this box by using 'vagrant add' if you like, and attempting to
run the acceptance tests as per those instructions.

Reference
---------

  [1]: https://github.com/jedi4ever/veewee/blob/master/doc/vagrant.md "veewee vagrant instructions"

