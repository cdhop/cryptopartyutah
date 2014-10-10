---
layout: post
title:  "Setting up a Tor Hidden Service"
date:   2014-10-10 07:46:00
categories: howto
---

#### Why run a hidden service?

It has been said that the printing press taught everyone how to read, and that the Internet taught everyone how to write.  While that is debatable, it is certainly true that these technologies 
have dramatically impacted humanity's ability to express and comsume ideas.

A common approach to obtaining candid information is to provide a way for people to communicate anonymously.  As Oscar Wilde said, "Man is least himself when he talks in his own person. Give 
him a mask, and he will tell you the truth."  Tor hidden services provide a means for people to communicate anonymously, and speak with candor.  

#### What do you need to run a hidden service?

While you can run a hidden service on any computer, and nearly any operating system, it is recommended (for security reasons) to use open source software.  The reason is that open source software
can be audited, and changed by the community that uses it, and is therefore more trustworthy than proprietary software (where they may have be beholden to other groups and interests).
This tutorial describes how to use software provided by the Debian and Tor Projects to create a hidden service.  

It is generally a good idea (for availablity) to place the service on a 
system with a 'always on' connection to the Internet.  You should be mindful of any acceptable use policies if you plan on hosting the service with a provider.


#### Step 1: Install Tor

Anyone who has spent even a limited amount of time with debian-based systems are familiar with its software package management system.  Instead of installing Tor from source (which is possible), 
I prefer to use package-management whenever possible (easier to update and maintain).  

While Tor is available from the default debian project repositories, it is usually not as up to date as from the Tor Project repositories.  So we will first install the Tor Project's repositories into the Debian package management system.

The default repositories are found in the /etc/apt/sources.list file.  You can add the Tor Project's repository by adding the following line to the file:

    deb     http://deb.torproject.org/torproject.org <DISTRIBUTION> main

You should replace the <DISTRIBUTION> label with the codename for your version of Debian (for example wheezy for Debian 7.x). 

The packages are signed using the Tor Project's GPG Keys.  So we will need to add the key to Apt in order to use the repository.  Use the following commands:

     # gpg --keyserver keys.gnupg.net --recv 886DDD89
	 # gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

Now we need to update apt now that we have added the Tor project's repositories:

     # apt-get update

With the repository updated, we will install a package which makes keepig the Tor project's signing keys up to date:

     # apt-get install deb.torproject.org-keyring

Finally,  we install Tor:

     # apt-get install tor

You should now have the Tor service running on your system.  Time for the next step.

#### Step 2: Install a Web Server

In most cases, a hidden service is just a website accessible through Tor.  As with any other website, we will need a webserver.  Any webserver will do the job, but there are some special 
considerations associated with running a hidden-service.  

Probably the most important is to configure the webserver to only answer queries from the host itself.  It will still 'work' if you don't 
do this, but it could defeat your efforts to be anonymous if your site can be reached from outside the Tor network. 

Because there are many different webservers, and several tutorials available, I will not go into any further details on how to 
configure them.

Note: Your hidden service can be any service commonly available on the Internet (ssh, IRC, etc).

#### Step 3: Configure the Hidden Service

Now that you have Tor and a webserver installed and running, its time to configure the hidden service.  In order to do this, we will need to reconfigure the tor service;  The tor service is configured
using the /etc/tor/torrc file.  Inside the torrc file there is a section for 'location-hidden services.'  There will be some example configurations for hidden services (commented out).  They will look
similar to this:

    # HiddenServiceDir /var/lib/tor/hidden_service/
    # HiddenServicePort 80 127.0.0.1:8080

The HiddenServiceDir directive points to the path where the 'pivate_key' and the 'hostname' files for the hidden service exist.  The 'pivate_key' is a secret which you should protect from disclosure, and
the 'hostname' file has the .onion address that people will use to access the hidden service.  Both of theses files will be generated by the tor service. It is important that the 'debian-tor' user have 
full permissions to this directory.  I would suggest placing the hidden service directory in '/var/lib/tor/'.

The HiddenServicePort directive identifies the port the service will be accessible on inside the tor network, and the local address and port of the service.  

After modifying the torrc file, and creating the directory, you will need to restart the tor service in order to make the hidden service active.

#### Conclusion

You should now have a working Tor hidden-service (the address for your hidden service can be found in the 'hostname' file mentioned above).  

---

#### Reference(s):

[Configuring Hidden Services for Tor](https://www.torproject.org/docs/tor-hidden-service.html.en)