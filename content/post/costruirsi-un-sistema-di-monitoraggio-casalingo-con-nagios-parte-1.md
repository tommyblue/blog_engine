+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "nagios", "nginx", "debian voyage", "apache", "monitoring", "alix", "embedded", "lighttpd", "php", "postfix"]
date = 2010-02-12T18:49:08Z
description = ""
draft = false
slug = "costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1"
tags = ["informatica", "how-to", "nagios", "nginx", "debian voyage", "apache", "monitoring", "alix", "embedded", "lighttpd", "php", "postfix"]
title = "Costruirsi un sistema di monitoraggio \"casalingo\" con Nagios - parte 1"

+++

<img class="alignleft size-full wp-image-813" title="Embedded PC" src="/uploads/2010/02/embedded.jpg" alt="" width="300" height="254" />Se, come me, avete vari server a giro per il mondo a cui fare da baby-sitter, probabilmente avrete sentito la necessità  di avere tutto sotto controllo e di scoprire (e magari risolvere) i problemi non appena si presentano.

Dopo aver configurato sistemi di monitoraggio per alcune P.A. e aziende, mi sono deciso a farlo anche per i miei server e descriverò in queste pagine ciò che ho fatto o sto ancora facendo.

Dividerò questa guida in più parti, per renderla più leggibile e per poter facilmente aggiungere nuove parti via via che incremento le funzionalità  del sistema.

Questa prima parte descrive l'<strong>hardware</strong> scelto, l'<strong>installazione del sistema operativo</strong> e l'<strong>installazione base di <a title="Nagios" href="http://www.nagios.org/" target="_blank">Nagios</a></strong>.
<!--more-->
<h3>Hardware</h3>
La scelta dell'hardware è caduta su un <em>embedded</em> acquistato (per circa 80â‚¬) su <a title="PC Engines" href="http://www.pcengines.ch" target="_blank">pcengines.ch</a> ampiamente in grado di fornire la <strong>potenza</strong> necessaria allo scopo e con <strong>consumi</strong> estremamente limitati.

Nello specifico ecco le caratteristiche principali:
<div id="_mcePaste">
<ul>
	<li><strong>CPU</strong>: 500 MHz AMD Geode LX800</li>
	<li><strong>DRAM</strong>: 256 MB DDR DRAM</li>
	<li><strong>Storage</strong>: CompactFlash socket</li>
	<li><strong>Power</strong>: DC jack or passive POE, min. 7V to max. 20V</li>
	<li><strong>Expansion</strong>: 2 miniPCI slots, dual USB port</li>
	<li><strong>Connectivity</strong>: 2 Ethernet channels (Via VT6105M 10/100)</li>
</ul>
</div>
Oltre alla scheda ho acquistato anche il case (damn! non avevano quello rosa shocking!) e l'alimentatore.

Costo complessivoÂ <strong>101,31â‚¬</strong> così distribuiti:
<ul>
	<li><strong>Scheda</strong>: 72,23 â‚¬</li>
	<li><strong>Case</strong>: 6,63 â‚¬</li>
	<li><strong>Alimentatore</strong>: 4,05 â‚¬</li>
	<li><strong>Spedizione</strong>: 18,40 â‚¬</li>
</ul>
A questo è necessario aggiungere una memoria <strong>CompactFlash</strong> (io ne ho usata una da 2GB), un <strong>lettore/scrittore di tali memorie</strong> e un <strong>adattatore seriale&lt;=&gt;USB</strong> (o soltanto un cavo seriale se avete una porta adatta). Attenzione al cavo seriale che deve essere RS-232 altrimenti la connessione non funziona.
<h3>Sistema operativo</h3>
Il sistema operativo scelto è <a title="Debian Voyage" href="http://linux.voyage.hk/" target="_blank">Debian Voyage</a>, una versione di Debian ottimizzata per le piattaforme <strong>embedded x86</strong>. La sua installazione sulla CompactFlash è estremamente semplice e veloce (per i dettagli vi rimando alla <a title="Wiki di Debian Voyage" href="http://wiki.voyage.hk/dokuwiki/doku.php?id=installation" target="_blank">pagina wiki dedicata</a>).
Una volta installato si può montare la memoria nella mainboard e agganciare il pc via seriale. Per visualizzare la console remota si può usare il software <strong>screen</strong>:
<pre>screen /dev/ttyUSB0 38400</pre>
Si può quindi alimentare la scheda e osservare il boot. Per accedere la prima volta a voyager usare l'utente <em>root </em>con password <em>voyage</em>.
Consiglio di configurare subito la rete con un ip statico (usate <em>/etc/network/interfaces</em>) e installare <em>openssh-server</em> che permetterà  di lavorare in remoto con la console preferita.

Per prepararsi all'installazione di Nagios dobbiamo fare un po' di cose:
<pre>apt-get install locales dialog build-essential apache2 libapache2-mod-php5 mailx postfix
addgroup --system nagios
adduser --system --no-create-home --home /usr/local/nagios --ingroup nagios --disabled-password nagios
addgroup --system nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagcmd www-data</pre>
Configuriamo <a title="Postfix" href="http://www.postfix.org" target="_blank">Postfix</a> con i parametri corretti per la nostra connessione e inseriamo in <em>/etc/aliases</em> l'alias per l'utente root:
<pre>postmaster: root
nagios: root
root: io@mio-dominio.com</pre>
e aggiorniamo:
<pre>newaliases
</pre>
Anzichè <a title="Apache" href="http://www.apache.org" target="_blank">Apache</a> (un po' oneroso in termini di memoria consumata) volevo usare <a title="Nginx" href="http://nginx.org/" target="_blank">Nginx</a> ma per configurarlo per fornire pagine <a title="PHP" href="http://www.php.net" target="_blank">PHP</a> è necessario lavorarci un po', quindi lascio questa configurazione per il futuro (considererò anche l'eventuale uso di <a title="Lighttpd" href="http://www.lighttpd.net/" target="_blank">Lighttpd</a>).
<h3>Nagios</h3>
Si può quindi iniziare a installare il software di monitoraggio, ovviamente <a title="Nagios" href="http://www.nagios.org/" target="_blank">Nagios</a>. Per alcuni check potrebbero essere necessari alcuni pacchetti, eccone alcuni tra i più comuni:
<pre>apt-get install libgd2-xpm libgd2-xpm-dev libpng3 libpng3-dev libjpeg62 libjpeg-dev zlib1g zlib1g-dev libnet-snmp-perl snmp libssl-dev libpq-dev libmysqlclient15-dev smbclient qstat fping libradiusclient-ng-dev libldap2-dev</pre>
Scarichiamo <a title="Download Nagios Core" href="http://www.nagios.org/download/core/" target="_blank">Nagios Core</a> in <em>/usr/src</em> e compiliamolo:
<pre>tar xzfÂ nagios-3.2.0.tar.gz
cd nagios-3.2.0/
./configure --prefix=/usr/local/nagios --with-command-group=nagcmd --with-httpd-conf=/etc/apache2/conf.d/
make all
make install
make install-init
make install-commandmode
make install-config
make install-webconf</pre>
Per ulteriori informazioni seguite la <a title="Guida a Nagios" href="http://nagios.sourceforge.net/docs/3_0/quickstart.html" target="_blank">guida ufficiale</a>.
Compiliamo e installiamo anche i plugin, scaricati da <a title="Download Nagios Plugins" href="http://www.nagios.org/download/plugins/" target="_blank">qui</a>:
<pre>tar xzf nagios-plugin-1.4.14.tar.gz
cd nagios-plugin-1.4.14
./configure Â --prefix=/usr/local/nagios --with-nagios-user=nagios --with-nagios-group=nagios
make
make install</pre>
Creiamo adesso la password per l'accesso a Nagios:
<pre>htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin</pre>
Se cambiate il nome utente sostituite tutte le occorrenze di <em>nagiosadmin</em> col nuovo utente nel file <em>/usr/local/nagios/etc/cgi.cfg</em>.
Aggiungiamo Nagios all'avvio del sistema:
<pre>update-rc.d nagios defaults</pre>
e iniziamo la configurazione. Una volta terminato, prima di lanciare o riavviare Nagios, possiamo verificare la correttezza della configurazione con:
<pre>/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
</pre>
La prima parte della guida termina qui, nella prossima vedremo come configurare i check di base e i controlli remoti con <a title="Nagios NRPE" href="http://www.nagios.org/download/addons/" target="_blank">Nagios NRPE</a>.

<a href="http://www.tommyblue.it/2010/02/17/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-2/"><strong>Leggi la seconda parte della guida</strong></a>