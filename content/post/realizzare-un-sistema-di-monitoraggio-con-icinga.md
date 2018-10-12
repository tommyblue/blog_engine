+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "monitoring", "software libero", "icinga", "nagios"]
date = 2011-03-08T15:45:38Z
description = ""
draft = false
slug = "realizzare-un-sistema-di-monitoraggio-con-icinga"
tags = ["informatica", "how-to", "monitoring", "software libero", "icinga", "nagios"]
title = "Realizzare un sistema di monitoraggio con Icinga"

+++

In questa breve guida spiegherò come installare Icinga (un fork di Nagios che ha ormai superato il <em>genitore</em>) e Icinga Web su Ubuntu 10.04 server.

Molti passi sono uguali a quelli che ho già  descritto nelle due guide sull'installazione di Nagios (<a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/">1</a> e <a href="http://www.tommyblue.it/2010/02/17/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-2/">2</a>).
<h2>Operazioni preliminari</h2>
Installare i pacchetti necessari:
<pre>apt-get install apache2 bsd-mailx build-essential libgd2-xpm-dev libjpeg62 libjpeg62-dev libpng12-0 libpng12-0-dev snmp libsnmp-base git-core mysql-server mysql-client libdbi0 libdbi0-dev libdbd-mysql</pre>
Aggiungere utenti e gruppi:
<pre>addgroup --system icinga
adduser --system --no-create-home --home /usr/local/icinga --ingroup icinga --disabled-password icinga
addgroup --system icinga-cmd
usermod -a -G icinga-cmd icinga
usermod -a -G icinga-cmd www-data</pre>
Creare il database:
<pre> #&gt; mysql -u root -p
 mysql&gt; CREATE DATABASE icinga;
 GRANT USAGE ON *.* TO 'icinga'@'localhost' IDENTIFIED BY 'icinga' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;
 GRANT SELECT , INSERT , UPDATE , DELETE ON icinga.* TO 'icinga'@'localhost';
 FLUSH PRIVILEGES ;
 quit</pre>
Scaricare Icinga:
<pre>cd /usr/src
git clone git://git.icinga.org/icinga-core.git
cd icinga-core/
git submodule init
git submodule update
./configure --with-command-group=icinga-cmd --enable-idoutils
make all
make fullinstall
make install-api
cd /usr/local/icinga/etc/
cp idomod.cfg-sample idomod.cfg
cp ido2db.cfg-sample ido2db.cfg</pre>
Editare i due ultimi file per adattarli alle configurazioni del database. Nel file <em>/usr/local/icinga/etc/icinga.cfg</em> scommentare la riga:
<pre>broker_module=/usr/local/icinga/bin/idomod.o config_file=/usr/local/icinga/etc/idomod.cfg</pre>
Creare le tabelle:
<pre> #&gt; cd /path/to/icinga-src/module/idoutils/db/mysql
 #&gt; mysql -u root -p icinga &lt; mysql.sql</pre>
<strong>Edit 15/03/11:</strong>
Ho dovuto modificare il file <em>/usr/local/icinga/etc/objects/commands.cfg</em> perchè il path al comando <em>mail</em> era sbagliato, quindi modificate le definizioni di <em>notify-host-by-email</em> e <em>notify-service-by-email</em> per utilizzare<em> /usr/bin/mail</em> e non <em>/bin/mail</em>.

Per terminare aggiungere Icinga ai servizi di avvio e lanciare Ido2db e Icinga:
<pre>update-rc.d icinga defaults
/etc/init.d/ido2db start
/etc/init.d/icinga restart</pre>
<h2>Plugins</h2>
Scaricare e installare i <a href="http://www.nagiosplugins.org/" target="_blank">plugin di Nagios</a>. Si faccia riferimento alla<a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/" target="_blank"> guida di Nagios</a> per l'installazione, si presti solo attenzione alle differenti opzioni di configurazione:
<pre>./configure --prefix=/usr/local/icinga --with-cgiurl=/icinga/cgi-bin --with-htmurl=/icinga --with-nagios-user=icinga --with-nagios-group=icinga</pre>
<h2>Configurazione dei check</h2>
Per la configurazione degli host e dei servizi potete vedere le mie precedenti guide per Nagios: <a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/">parte 1</a> e <a href="http://www.tommyblue.it/2010/02/17/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-2/">parte 2</a>.
<h2>Le interfacce web</h2>
Icinga ha a disposizione due interfacce web: la classica interfaccia CGI e la nuova Icinga Web. Le due installazioni possono convivere tranquillamente.
<h3>Icinga</h3>
Installare i CGI:
<pre>make cgis
make install-cgis
make install-html
make install-webconf</pre>
Creare l'utente e la password per l'accesso:
<pre>htpasswd -c /usr/local/icinga/etc/htpasswd.users icingaadmin</pre>
<h3>Icinga Web</h3>
Installare il necessario:
<pre>apt-get install php5 php5-cli php-pear php5-xmlrpc php5-xsl php5-gd php5-ldap php5-mysql
a2enmod rewrite</pre>
Scaricare e installare Icinga Web:
<pre>cd /usr/src
git clone git://git.icinga.org/icinga-web.git
cd icinga-web
./configure
make install
make install-apache-config</pre>
Creare il database e lo schema:
<pre># mysql -u root -p

mysql&gt; CREATE DATABASE icinga_web;
       GRANT USAGE ON *.* TO 'icinga_web'@'localhost' IDENTIFIED BY 'icinga_web' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0;
       GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX ON icinga_web.* TO 'icinga_web'@'localhost';
       quit

# make db-initialize</pre>
E, per finire:
<pre>/etc/init.d/icinga restart
/etc/init.d/apache2 restart</pre>
Se avete utilizzato le impostazioni di default non dovete fare altro, altrimenti date una lettura alla <a title="Installation of the Icinga Web Frontend" href="http://docs.icinga.org/latest/en/icinga-web-scratch.html" target="_blank">guida ufficiale</a>. Riavviate apache e connettetevi al server: <em>http://&lt;hostname&gt;/icinga-web</em>
<h2>Webografia</h2>
<ul>
	<li><a title="Icinga with IDOUtils Quickstart" href="http://docs.icinga.org/latest/en/quickstart-idoutils.html" target="_blank">http://docs.icinga.org/latest/en/quickstart-idoutils.html</a></li>
	<li><a title="Installation of the Icinga Web Frontend" href="http://docs.icinga.org/latest/en/icinga-web-scratch.html" target="_blank">http://docs.icinga.org/latest/en/icinga-web-scratch.html</a></li>
</ul>