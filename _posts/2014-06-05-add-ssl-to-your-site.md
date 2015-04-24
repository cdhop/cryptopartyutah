---
layout: post
title:  "Add SSL to your site"
date:   2014-06-05 07:46:00
categories: howto
---

Part of the [Reset the Net](https://resetthenet.org) initative is encouraging webmasters to implement SSL on their sites.  SSL uses
encryption to protect the content of the communications between the visitor and the site.  While using SSL might be 'optional' for 
a site that only serves static information (and doesn't have users submit their personal information), it is irresponsible for sites
that have visitors submit their information.  We will walk people through the steps necessary to protect their 
sites with SSL.

### Assumptions

This article assumes that your website is hosted on a server running Linux (We will cover Ubuntu/Debian based systems).  We also assume
that you have admin/root access on your server.  If you are hosted with a service where you don't have admin/root access, then this 
article will still be useful, but you will probably need to contact your service provider for assistance in some of the steps described 
below.

### Step 1: Generating your Private Key and Certificate Signing Request (CSR)

You will need a private key (which your server use to communicate securely), and a CSR (which you will use to obtain a certificate).

We will be using OpenSSL for this step.  There are a number of options (which we will explain) available.  We will start with the following
command:

    # openssl req -new -newkey rsa:4096 -keyout yourdomain.key -out yourdomain.csr

Explanation:

* 'req -new' tells openssl that we will be creating a CSR 
* '-newkey' we will also be creating a private key
* 'rsa:4096' the private key will be a RSA key with a keysize of 4096 bits (Note: the minimum keysize currently accepted by certificate authorities is 2048)
* '-keyout yourdomain.key' specify the filename of the private key (Please change 'yourdomain' to your domain name)
* '-out yourdomain.car' specify the filename of the CSR (Again change 'yourdomain' to your domain name)

There are other options that you could use, but this generates an encrypted private key and a CSR.  If you want to generate an unencrypted private key, 
then include '-nodes' after the 'rsa:4096' option.

OpenSSL will prompt you for a passphase for your key (unless you included the '-nodes' option), and ask you for additional information (some of which is optional).  
Once you finish, you will have a private key and CSR.

On Debian/Ubuntu, you will generally want to store your private key in the '/etc/ssl/private' directory. 

You will use the CSR in the next step to obtain your certificate.

###  Step 2: Obtaining a certificate

A signed certificate is used by a browser to authenticate, and help setup secure communications using SSL/TLS.  A Certificate Authority (CA) is a trusted organization
which is recognized by most browsers to authenticate sites using SSL/TLS.  In order to get a CA to generate a signed certificate you must verify your information, and 
usually pay a fee for their service (Note: there are some 'free' certificate authorities).  

Generally, there are three 'levels' of verification/validation by CAs:

* Domain validation - usually they will send an email message to one of the email addresses associated with the domain name registration.
* Organization validation - The CA will investigate your organization to verify its legitimacy (usually more expensive)
* Extended validation - Like Organization validation, but even more rigorous (usually done with large organizations and financial institutions)

The process will vary, but you will at some point provide the CA with the CSR you generated in Step 1.

Once they have completed validation, the CA will issue a signed certificate for your domain.  Usually they will also include several other certificates asscoiated with
their chain of trust.

As an alternative, you can 'self-sign' and generate your own certificate.  This is simpler and usually cheaper that getting one from a CA, but will most probably 
cause a visitor's browser to alert and warn of 'an untrusted site'.  To generate your own certificate, use OpenSSL as follows:

    # openssl x509 -req -days 365 -in yourdomain.csr -signkey yourdomain.key -out yourdomain.crt

Explanation:

* 'x509 -req' tells openssl that we will be creating a signed-certificate
* '-days 365' our certificate will be valid for one year (most certificates are signed by CAs for the length of period)
* '-in yourdomain.csr' OpenSSL will use the CSR you generated in Step One 
* '-signkey yourdomain.key' OpenSSL will use your private key to 'sign' the certificate
* '-out yourdomain.crt' specify the filename of the certificate

Once you have your certificate(s) you will generally want to keep them in 'certs' directory.  On Debian/Ubuntu systems the 'certs' directory is, '/etc/ssl/certs'.  

### Step 3: Configuring your webserver to use SSL

Now that you have your private key and certificate(s), it is time to configure your server to use SSL/TLS.  We will cover configuring Apache (A later article will cover using NGINX).

#### Configuring Apache on Debian/Ubuntu

You will need to enable a few Apache modules in order to use SSL/TLS.  You can enable these modules with the following commands:

    # a2enmod ssl
    # a2enmod headers
    # a2enmod rewrite

The first module is the only one truly necessary to get SSL working, but the other modules will be used in our example configuration, so it is a good idea to add them now.

Next, you will need to create/modify the VirtualHost files located at: '/etc/apache2/sites-available'.  By default, there are two files, '000-default.conf' and 'default-ssl.conf'.  
The '000-default.conf' file is configured to serve http, and the 'default-ssl.conf' is configured for SSL.  

Note: the 'default-ssl.conf' site is not enabled by default. You can enable it with the following command:

    # a2ensite default-ssl.conf

There are many ways to configure SSL, but the example we will show you redirects all http traffic to https (this is why we enabled the 'rewrite' Apache module).  
Below is an example (which you can use unmodified) for the '000-default.conf' file:

    <VirtualHost *:80>
        ReWriteEngine on
        ReWriteCond %{SERVER_PORT} !^443$
        ReWriteRule ^/(.*) https://%{HTTP_HOST}/$1 [NC,R,L]
    </VirtualHost>

Next, is the 'default-ssl.conf' file (This one is more involved).

    <IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerName yourdomain
        ServerAlias www.yourdomain

        DocumentRoot /var/www/
        <Directory />
                Options FollowSymLinks
                AllowOverride None
        </Directory>
        <Directory /var/www/>
                Options FollowSymLinks MultiViews
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog ${APACHE_LOG_DIR}/ssl_access.log combined

	    # Setup  HTTP Strict Transportation Security
        Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"

        SSLEngine on

        SSLCertificateFile    /etc/ssl/certs/yourdomain.crt
        SSLCertificateKeyFile /etc/ssl/private/yourdomain.key
        SSLCertificateChainFile /etc/ssl/certs/yourdomain.chain

	    SSLProtocol ALL -SSLv2 -SSLv3
	    SSLHonorCipherOrder On
	    SSLCipherSuite AES256+EECDH:!aNULL

    </VirtualHost>
    </IfModule>

Key points of interest are the lines which start with 'SSLCertificate', you will want to make sure that they are pointing to the files you created/obtained in steps one and two.
The line that starts with 'Header' will help prevent visitors to your site from connecting in the future via http, and is a good security move. You will need to modify this 
example to match your domain/website.

Once you are satified the these files, you'll need to restart Apache to make your changes effective.  

    # service apache2 restart

Note: If your private key is encrypted, then you will be prompted for your password.

### Step 4: Test Your Site

Now it is time to verify that your site is working with SSL.  Certainly, visiting the site is a good step, but there is a tool available online with will give your site's SSL Configuration a thorough testing:

[SSL Labs - SSL Test](https://ssllabs.com/ssltest) 

