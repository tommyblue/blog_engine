+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "nagios", "monitoring", "alix", "apache", "debian", "debian voyage", "embedded", "lighttpd", "nrpe", "php", "postfix", "nginx"]
date = 2010-02-17T13:01:37Z
description = ""
draft = false
slug = "costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-2"
tags = ["informatica", "how-to", "nagios", "monitoring", "alix", "apache", "debian", "debian voyage", "embedded", "lighttpd", "nrpe", "php", "postfix", "nginx"]
title = "Costruirsi un sistema di monitoraggio \"casalingo\" con Nagios â€“ parte 2"

+++

<a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/"><strong>Leggi la prima parte della guida</strong></a>

In questa seconda parte della guida illustrerò alcune <strong>configurazioni di base</strong> per i check di <a title="Nagios" href="http://www.nagios.org/" target="_blank">Nagios</a> e l'uso dell'addon <strong>NRPE</strong> per check locali su sistemi remoti.
<h3>La struttura</h3>
In questa guida prenderò in considerazione la struttura qui si seguito che permette di illustrare vari tipi di configurazione:
<p style="text-align: center;"><img class="aligncenter size-full wp-image-860" title="Schema Nagios" src="/uploads/2010/02/schema-nagios.jpg" alt="" width="450" height="454" /></p>
Una panoramica sugli host e i servizi:
<ul>
	<li>Host A, server Linux con:
<ul>
	<li>Server HTTP Apache</li>
	<li>VMWare Server con una macchina virtuale E con un server Zimbra</li>
</ul>
</li>
	<li>Host B, server Linux con:
<ul>
	<li>Server HTTP Apache</li>
	<li>Server MySQL</li>
</ul>
</li>
</ul>
Quindi E dipende da C che a sua volta dipende da A. Invece D dipende da B.
Entrambi i server Apache rispondono sulle porte 80 e 443, l'interfaccia di amministrazione di VMWare Server risponde sulla porta 8333 (con SSL).
La macchina virtuale Zimbra fornisce i servizi SMTP, POP3 e le interfaccie di webmail e amministrazione (porta 7071).
Infine nella macchina B il server MySQL risponde solo sull'interfaccia locale, non è quindi possibile accedervi dall'esterno.

<!--more-->Negli esempi successivi gli elementi <strong>A</strong>, <strong>C</strong> ed <strong>E</strong> saranno del cliente <em>Company A</em> (dominio <em>company-a.com</em>) e <strong>B</strong> e <strong>D</strong> saranno del cliente <em>Company B</em> con dominio <em>company-b.com</em>.
I nomi host saranno i seguenti:
<ul>
	<li><em>A =&gt; web.company-a.com
</em></li>
	<li><em>C (macchina virtuale) =&gt; mail.company-a.com
</em></li>
	<li><em>B =&gt; web.company-b.com</em></li>
</ul>
Per un maggior dettaglio nella spiegazione delle singole configurazioni tenete sempre sott'occhio la guida ufficiale alla pagina <a href="http://nagios.sourceforge.net/docs/3_0/objectdefinitions.html" target="_blank"><strong>Object Definitions</strong></a>.
<h3>Organizzazione dei file</h3>
Una volta installato Nagios seguendo la <a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/">prima parte della guida</a>, troverete tutte le configurazioni in <em>/usr/local/nagios/etc</em>. Il file che <em>comanda</em> è <em>nagios.cfg</em> il quale poi richiama tutti gli altri. àˆ quindi possibile, e consigliabile, creare una gerarchia di file che possa poi più facilmente permettere di gestire tutte le configurazioni (senza <em>perdersi</em> per strada i vari pezzi).
Nel file <em>nagios.cfg</em> ci sono due direttive inerenti questo aspetto e sono <em>cfg_file</em> e <em>cfg_dir</em>. La prima indica direttamente un file da cui leggere ulteriori configurazioni, la seconda indica intere directory da cui saranno inclusi tutti i file che terminano con <em>.cfg</em>. Io consiglio di intervenire usando questa seconda direttiva, le cartelle che ho creato sono:
<pre>cfg_dir=/usr/local/nagios/etc/personalized_objects
cfg_dir=/usr/local/nagios/etc/servers
cfg_dir=/usr/local/nagios/etc/groups</pre>
Oltre alle due cartelle con le configurazioni dei server e dei gruppi, ho aggiunto una cartella in cui inserirò i <em>template</em> personalizzati, ad esempio con <em>timeperiods</em> o <em>contact groups</em> diversi da quelli standard.
<h3>Gruppi di host e servizi</h3>
àˆ possibile definire dei gruppi di host (ad esempio a seconda dell'azienda di appartenenza o del tipo di hardware) e dei gruppi di servizi (server di posta, server web, ecc.). Personalmente inserisco queste configurazioni nella cartella <em>groups</em>.

Esempi di configurazione sono i seguenti:
<pre>define hostgroup{
    hostgroup_nameÂ     companyA-servers
    aliasÂ Â Â Â Â Â Â Â Â Â     Company A Servers
    membersÂ Â Â Â Â Â Â Â     mail.company-a.com,web.company-a.com
}
define hostgroup{
    hostgroup_nameÂ     companyB-servers
    aliasÂ Â Â Â Â Â Â Â Â Â     Company B Servers
    membersÂ Â Â Â Â Â Â Â     web.company-b.com
}
define servicegroup{
    servicegroup_name  web-servers
    alias              Web Servers
    members            web.company-a.com,HTTP,web.company-b.com,HTTP
}</pre>
In entrambi i casi gli host indicati in <em>members</em> devono ricalcare il nome con cui quegli host sono definiti (attributo <em>host_name</em>). Nel caso dei servizi, oltre al nome dell'host, deve essere indicato il nome del servizio (anche in questo caso deve essere uguale a quello inserito in <em>service_description</em>).
<h3>Definizione degli host</h3>
Iniziamo con la configurazione dei server. I file <em>web.company-a.com.cfg</em>, <em>web.company-b.com.cfg</em> e <em>mail.company-a.com.cfg</em> verranno creati nella cartella <em>servers</em>. Non c'è molto da spiegare, inserisco dei commenti direttamente nelle configurazioni:

<em><strong>web.company-a.com.cfg</strong></em>
<pre>define host {
    useÂ Â Â Â Â Â Â Â Â Â Â Â  linux-server   ;   Template da cui ereditare
    host_nameÂ Â Â Â Â Â  web.company-a.com   ;   L'host name è ciò che viene usato per identificare l'host negli altri file
    aliasÂ Â Â Â Â Â Â Â Â Â  CompanyA Web Server
    addressÂ Â Â Â Â Â Â Â  1.2.3.4
    hostgroupsÂ Â Â Â Â  comapanyA-servers   ;   Come in hostgroup, tale configurazione può essere alternativa o in aggiunta
}</pre>
<em><strong>web.company-b.com.cfg</strong></em>
<pre>define host {
    useÂ Â Â Â Â Â Â Â Â Â Â Â  linux-server
    host_nameÂ Â Â Â Â Â  web.company-b.com
    aliasÂ Â Â Â Â Â Â Â Â Â  CompanyB Web Server
    addressÂ Â Â Â Â Â Â Â  1.2.3.5
    hostgroupsÂ Â Â Â Â  comapanyB-servers
}</pre>
<em><strong>mail.company-a.com.cfg</strong></em>
<pre>define host {
    useÂ Â Â Â Â Â Â Â Â Â Â Â  linux-server
    host_nameÂ Â Â Â Â Â  mail.company-a.com
    aliasÂ Â Â Â Â Â Â Â Â Â  CompanyA Web Server
    addressÂ Â Â Â Â Â Â Â  1.2.3.6
    hostgroupsÂ Â Â Â Â  comapanyA-servers
    parentsÂ Â Â Â Â Â Â Â  web.company-a.com   ;   L'host da cui questo host dipende
}</pre>
<h3>Definizione dei servizi</h3>
La definizione dei servizi è direttamente collegata ai plugin, ovvero usano questi ultimi per effettuare i check. In verità  il valore dell'attributo <em>check_command</em>, anche se in genere ricalca il nome del plugin (i plugin sono nella cartella <em>libexec</em>), non lo indica direttamente ma ha una corrispondenza nel valore dell'attributo <em>command_name</em> nella definizione di un comando (file <em>etc/objects/commands.cfg</em>).

<em><strong>mail.company-a.com.cfg</strong></em>
<pre>define service {
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â  mail.company-a.com
 service_descriptionÂ Â Â Â  SMTP
 check_commandÂ Â Â Â Â Â Â Â Â Â  check_smtp!-t 5
}
define service {
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â  mail.company-a.com
 service_descriptionÂ Â Â Â  IMAP
 check_commandÂ Â Â Â Â Â Â Â Â Â  check_imap!-t 5
}
define service {
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â  mail.company-a.com
 service_descriptionÂ Â Â Â  POP3
 check_commandÂ Â Â Â Â Â Â Â Â Â  check_pop!-t 5
}</pre>
Nella direttiva <em>check_command</em> viene indicato il tipo di comando da eseguire. Dopo il punto esclamativo vengono indicati gli argomenti. Se date uno sguardo a <em>etc/objects/commands.cfg</em> vedrete che gli argomenti vengono passati al plugin con <em>$ARG1$, $ARG2$, ecc</em>. In alcuni è presente soltanto un argomento, quindi nella definizione del servizio, dopo il punto esclamativo, devono essere indicati tutti gli argomenti (tipo <em>./check_dummy -t pippo -x pluto</em>) mentre in altri comandi sono presenti più argomenti, spesso associati ad una specifica opzione (tipo <em>./check_dummy -t </em><em>$ARG1$</em><em> -x </em><em>$ARG2$</em>). Nella definizione del servizio, più argomenti possono essere indicati con più punti esclamativi (tipo <em>check_dummy!pippo!pluto</em>). Per avere più informazioni su un plugin lanciatelo con <em>libexec/check_dummy --help</em>.

Un esempio di check un po' più complesso può essere, ad esempio, quello necessario per controllare se l'interfaccia di amministrazione di Zimbra sta girando correttamente (HTTPS sulla porta 7071):

<em><strong>mail.company-a.com.cfg</strong></em>
<pre>define service{
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  mail.comapany-a.com
 service_descriptionÂ Â Â Â Â Â Â Â Â Â Â Â  ZimbraAdmin
 check_commandÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  check_http!"-H mail.company-a.com -p 7071 -w 5 -c 15 --ssl"
}</pre>
Com'è facile intuire, con <em>check_http</em> è possibile quindi monitorare ogni singolo sito presente su un server web.

Ecco gli altri file necessari per la nostra configurazione:

<em><strong>web.company-a.com.cfg</strong></em>
<pre>define service{
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  web.company-a.com
 service_descriptionÂ Â Â Â Â Â Â Â Â Â Â Â  HTTP
 check_commandÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  check_http   ;   Semplice check sulla porta 80
}</pre>
<pre>define service{
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  web.company-a.com
 service_descriptionÂ Â Â Â Â Â Â Â Â Â Â Â  VMWareAdmin
 check_commandÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  check_http!"-H web.company-a.com -p 8333 -w 5 -c 15 --ssl"
}</pre>
<em><strong>web.company-b.com.cfg</strong></em>
<pre>define service{
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  web.company-b.com
 service_descriptionÂ Â Â Â Â Â Â Â Â Â Â Â  HTTP
 check_commandÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  check_http
}</pre>
<h3>NRPE</h3>
L'ultima cosa che rimane da controllare è lo stato del server MySQL. Dato che il servizio risponde soltanto sull'interfaccia locale non è possibile controllarne direttamente lo stato dal server Nagios. L'addon<em> NRPE </em>fa proprio questo: installato sulla macchina da controllare, esegue dei check locali quando interrogato da Nagios.Il plugin da usare sul server è <em>check_nrpe</em> e l'argomento da passargli è il nome del check definito nel client, il quale a sua volta dovrà  associare questo nome ad un check locale (quindi sul client dobbiamo installare i plugin).

Su entrambe le macchine va compilatoÂ  l'addon:
<pre>tar xzf nrpe-2.12.tar.gz
cd nrpe-2.12/
./configure --enable-ssl
make all</pre>
A questo punto l'installazione tra host e client differisce. Per l'installazione nel client dei plugin seguite la <a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/" target="_blank">prima parte della guida</a>.

<strong>Host</strong>
<pre>make install-plugin</pre>
e quindi bisogna creare il template del comando:

<em><strong>commands.cfg</strong></em>
<pre>define command {
 command_nameÂ Â Â  check_nrpe
 command_lineÂ Â Â  $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}</pre>
<strong>Client</strong>

Se non è installato, installate <em>xinetd</em>:
<pre>apt-get install xinetd</pre>
Installate quindi il demone
<pre>make install-daemon
make install-daemon-config
make install-xinetd</pre>
Aggiungete NRPE al file <em>/etc/services</em>:
<pre>nrpe 5666/tcp # NRPE</pre>
Aggiungete l'ip del server Nagios al file <em>/etc/xinetd.d/nrpe</em> (in questo caso un fittizio <em>4.3.2.1</em>):
<pre>only_from = 127.0.0.1 4.3.2.1</pre>
Infine riavviate il server xinetd e controllate che NRPE sia in ascolto:
<pre>~# /etc/init.d/xinetd restart
~# netstat -at | grep nrpe
tcpÂ Â Â Â Â Â Â  0Â Â Â Â Â  0 *:nrpeÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  *:*Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  LISTEN</pre>
A questo punto si può testare il servizio in locale con:
<pre>~# /usr/local/nagios/libexec/check_nrpe -H localhost
NRPE v2.12</pre>
<strong>Controllare MySQL</strong>

Arriviamo al nostro obiettivo: controllare che il server MySQL stia correttamente girando. Creiamo un utente MySQL non privilegiato:
<pre>mysql&gt; CREATE USER 'nagiosCheck'@'localhost' IDENTIFIED BY 'some_pass';</pre>
Il check, lanciato da linea di comando, sarà  il seguente:
<pre>~# /usr/local/nagios/libexec/check_mysql -u nagiosCheck -p some_pass
Uptime: 1061012Â  Threads: 2Â  Questions: 192277Â  Slow queries: 0Â  Opens: 198Â  Flush tables: 1Â  Open tables: 64Â  Queries per second avg: 0.181</pre>
Inseriamo quindi tale check in <em>/usr/local/nagios/etc/nrpe.cfg</em>:
<pre>command[check_mysql]=/usr/local/nagios/libexec/check_mysql -u nagiosCheck -p some_pass</pre>
Da notare che nel server Nagios il nome dell'argomento da passare a <em>check_nrpe </em>sarà  <em>check_mysql</em> come definito tra le parentesi quadre.
A questo punto dal server Nagios si può testare il check remoto:
<pre>~# /usr/local/nagios/libexec/check_nrpe -H tomcat.mydomain.com -c check_mysql
Uptime: 1061534Â  Threads: 2Â  Questions: 192280Â  Slow queries: 0Â  Opens: 198Â  Flush tables: 1Â  Open tables: 64Â  Queries per second avg: 0.181</pre>
Se è tutto ok non resta che inserirlo tra i servizi dell'host <strong>B</strong>:

<em><strong>web.company-b.com.cfg</strong></em>
<pre>define service{
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  web.company-b.com
 service_descriptionÂ Â Â Â Â Â Â Â Â Â Â Â  MySQL
 check_commandÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  check_nrpe!check_mysql
}</pre>
E questo conclude la configurazione della nostra rete di test. Nella prossima <em>puntata</em> spiegherò come configurare dei server <em>slave</em> per effettuare check passivi, necessari, ad esempio, in configurazioni di rete complesse in cui il server <em>master</em> non può direttamente raggiungere gli host da controllare (se l'host da controllare è all'interno di una LAN, per dirne una).

<a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/"><strong>Leggi la prima parte della guida</strong></a>