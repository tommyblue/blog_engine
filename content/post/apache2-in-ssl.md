+++
author = "Tommaso Visconti"
categories = ["informatica", "software libero", "how-to", "apache", "ssl"]
date = 2006-05-07T05:42:27Z
description = ""
draft = false
slug = "apache2-in-ssl"
tags = ["informatica", "software libero", "how-to", "apache", "ssl"]
title = "Apache2 in SSL"

+++

<div>
<h2>Creazione del certificato</h2>
<pre>macondo:~# rm -rf /root/CertAuth
macondo:~# mkdir /root/CertAuth
macondo:~# chmod 700 /root/CertAuth
macondo:~# cd /root/CertAuth</pre>
<pre>macondo:~/CertAuth# /usr/lib/ssl/misc/CA.pl -newca
CA certificate filename (or enter to create)

Making CA certificate ...
Generating a 1024 bit RSA private key
...............++++++
..............................................................++++++
writing new private key to './demoCA/private/cakey.pem'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:IT
State or Province Name (full name) [Some-State]:Italia
Locality Name (eg, city) []:Firenze
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Tommyblue.it
Organizational Unit Name (eg, section) []:Tommyblue.it
Common Name (eg, YOUR name) []:Tommyblue
Email Address []:info@tommyblue.it</pre>
<pre>macondo:~/CertAuth# /usr/lib/ssl/misc/CA.pl -newreq
Generating a 1024 bit RSA private key
..................++++++
...++++++
writing new private key to 'newreq.pem'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:IT
State or Province Name (full name) [Some-State]:Italia
Locality Name (eg, city) []:Firenze
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Tommyblue.it
Organizational Unit Name (eg, section) []:Tommyblue.it
Common Name (eg, YOUR name) []:Tommyblue
Email Address []:info@tommyblue.it

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
Request (and private key) is in newreq.pem</pre>
<pre>macondo:~/CertAuth# /usr/lib/ssl/misc/CA.pl -sign
Using configuration from /usr/lib/ssl/openssl.cnf
Enter pass phrase for ./demoCA/private/cakey.pem:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number:
            9b:49:17:c6:49:1a:09:7a
        Validity
            Not Before: Oct 25 17:01:48 2005 GMT
            Not After : Oct 25 17:01:48 2006 GMT
        Subject:
            countryName               = IT
            stateOrProvinceName       = Italia
            localityName              = Firenze
            organizationName          = Tommyblue.it
            organizationalUnitName    = Tommyblue.it
            commonName                = Tommyblue
            emailAddress              = info@tommyblue.it
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Comment:
                OpenSSL Generated Certificate
            X509v3 Subject Key Identifier:
                FF:E0:BB:B6:A4:03:B7:8D:8F:32:51:3D:1D:A8:E9:84:5B:7C:4B:BA
            X509v3 Authority Key Identifier:
                keyid:6A:E5:B3:7D:68:BF:19:6F:E5:3D:5A:7D:23:90:3E:03:00:2A:41:23
                DirName:/C=IT/ST=Italia/L=Firenze/O=Tommyblue.it/OU=Tommyblue.it/CN=Tommyblue/emailAddress=info@tommyblue.it
                serial:9B:49:17:C6:49:1A:09:79

Certificate is to be certified until Oct 25 17:01:48 2006 GMT (365 days)
Sign the certificate? [y/n]:y

1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
Signed certificate is in newcert.pem</pre>
<pre>macondo:~/CertAuth# openssl rsa &lt; newreq.pem &gt; newkey.pem
Enter pass phrase:
writing RSA key</pre>
<pre>macondo:~/CertAuth# cp /root/CertAuth/demoCA/cacert.pem /etc/ssl/certs/cacert.pem
macondo:~/CertAuth# cp /root/CertAuth/newcert.pem /etc/ssl/certs/ldapcert.pem
macondo:~/CertAuth# cp /root/CertAuth/newkey.pem /etc/ssl/certs/ldapkey.pem
macondo:~/CertAuth# chmod 600 /root/CertAuth/newkey.pem</pre>
<h2>Configurazione di Apache2</h2>
Cominciamo aprendo, oltre alla porta 80, anche la porta 443
<pre>macondo:~# echo -e "Listen 80\nListen 443" &gt; /etc/apache2/ports.conf</pre>
Quindi attiviamo i moduli ssl necessari:
<pre>macondo:~# ln -s /etc/apache2/mods-available/ssl.conf /etc/apache2/mods-enabled/ssl.conf
macondo:~# ln -s /etc/apache2/mods-available/load.conf /etc/apache2/mods-enabled/ssl.load</pre>
Se adesso vogliamo che il nostro server sia raggiungibile sia in http che in https dobbiamo modificare il file <strong>/etc/apache2/sites-available/default</strong>:
<pre>NameVirtualHost *</pre>
diventa
<pre>NameVirtualHost *:80
NameVirtualHost *:443</pre>
La parte successiva (tra <strong>&lt;VirtualHost *&gt;</strong> e <strong>&lt;/VirtualHost&gt;</strong>) deve essere replicata, sostituendo <strong>&lt;VirtualHost *&gt;</strong> con <strong>&lt;VirtualHost *:80&gt;</strong> in un caso e <strong>&lt;VirtualHost *:443&gt;</strong> nell'altro.  Infine inserite le righe seguenti in <strong>&lt;VirtualHost *:443&gt;</strong>
<pre> &lt;VirtualHost *:443&gt;
   &lt;IfModule mod_ssl.c&gt;
    SSLEngine on
    SSLCACertificateFile        /etc/ssl/certs/cacert.pem
    SSLCertificateFile          /etc/ssl/certs/ldapcert.pem
    SSLCertificateKeyFile       /etc/ssl/certs/ldapkey.pem
    SetEnvIf User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown
   &lt;/IfModule&gt;
...
...
...</pre>
Se non lo fosse attiviamo il file appena modificato creando un link simbolico:
<pre>macondo:~# ln -s /etc/apache2/sites-available/default /etc/apache2/sites-enabled/000-default</pre>
Infine riavviamo Apache2:
<pre>macondo:~# /etc/init.d/apache2 restart</pre>
</div>