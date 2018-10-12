+++
author = "Tommaso Visconti"
categories = ["informatica", "nginx", "monitoring", "apache", "debian", "alix", "embedded", "lighttpd", "munin", "nrpe", "nsca", "php", "postfix", "how-to", "nagios", "debian voyage"]
date = 2010-09-16T13:51:16Z
description = ""
draft = false
slug = "configurare-i-check-passivi-in-nagios-per-l-integrazione-con-munin"
tags = ["informatica", "nginx", "monitoring", "apache", "debian", "alix", "embedded", "lighttpd", "munin", "nrpe", "nsca", "php", "postfix", "how-to", "nagios", "debian voyage"]
title = "Configurare i check passivi in Nagios per l'integrazione con Munin"

+++

Continuo la serie di guide sulla configurazione di Nagios spiegando come attivare i check passivi con <a href="http://www.nagios.org/download/addons" target="_blank">NSCA</a> e come usare Munin per avvertire Nagios di ciò che non va'.

Intanto ricordo i link alla prima e alla seconda parte della guida:
<ul>
	<li><a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/">Parte 1</a></li>
	<li><a href="http://www.tommyblue.it/2010/02/17/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-2/">Parte 2</a></li>
</ul>
Tornando a Nagios e Munin: l'uso dei check passivi può tornare utile se si va ad installare Nagios in una rete in cui è già  presente Munin che, per chi non lo conoscesse, è un software che crea grafici di andamento di una lunga serie di servizi o aspetti dei server (anch'esso configurabile con agenti su vari server e un'applicazione centralizzata per la raccolta dei dati).
Se Munin non fosse già  installato si può valutare una configurazione Nagios-centrica con i check effettuati da NRPE e i grafici fatti con <a href="http://nagiosgraph.sourceforge.net/" target="_blank">NagiosGraph</a>.

Nel mio caso era già  presente Munin e ho quindi optato per la configurazione dei check passivi.<!--more-->
<h2>Configurazione del server (Nagios e nsca)</h2>
Si comincia come sempre installando i pacchetti necessari:
<pre>apt-get install libmcrypt-dev xinetd</pre>
Quindi si scarica NSCA dalla <a href="http://www.nagios.org/download/addons" target="_blank">pagina degli addon di Nagios</a>, si scompatta, si compila e si installa:
<pre>tar xzf nsca-2.7.2.tar.gz
cd nsca-2.7.2/
./configure prefix=/usr/local/nagios --with-nsca-user=nagios --with-nsca-grp=nagcmd
make all
cp -a src/nsca /usr/local/nagios/bin/
cp sample-config/nsca.cfg /usr/local/nagios/etc/
chown nagios:nagcmd /usr/local/nagios/etc/nsca.cfg
chmod g+r /usr/local/nagios/etc/nsca.cfg
cp sample-config/nsca.xinetd /etc/xinetd.d/nsca</pre>
Bisogna anche aggiungere al file <em>/etc/services</em> il servizio NSCA con la riga:
<pre>nscaÂ Â  Â 5667/tcpÂ Â  Â # NSCA</pre>
Nel file <em>/etc/xinetd.d/nsca</em> bisogna modificare il parametro <em>only_from</em> per consentire l'accesso al server in cui gira Munin, poi possiamo riavviare xinetd.
<h2>Configurazione del client (send_nsca e Munin)</h2>
Nel client da cui arriveranno i check (ovvero dove gira Munin) bisogna ugualmente scaricare il pacchetto NSCA e compilarlo. Differisce l'installazione del binario che in questo caso è <strong>send_nsca</strong> e può essere posizionato dove si vuole (stessa cosa vale per il suo file di configurazione). Dato che nel mio caso Munin e Nagios sono sullo stesso server ho usato la directory di Nagios per ospitare questi file:
<pre>cp -a src/send_nsca /usr/local/nagios/bin/
cp sample-config/send_nsca.cfg /usr/local/nagios/etc/</pre>
Se i due software sono su server diversi potete impostare un metodo di cifratura nel file <em>send_nsca.cfg</em> e impostare una password (che deve essere la stessa sul server e sul client).

<strong>Proviamo adesso se <em>send_nsca</em> funziona.</strong> I check passivi consistono in una riga contenente:
<pre>HOSTNAME[tab]SERVIZIO[tab]CODICE[tab]DESCRIZIONE</pre>
quindi per fare un test possiamo creare un file con il contenuto:
<pre>hostAcaso Â  pippoÂ Â  0Â Â  OK</pre>
e fare un test di connessione con:
<pre>/usr/local/nagios/bin/send_nsca localhost -c /usr/local/nagios/etc/send_nsca.cfg &lt; test
1 data packet(s) sent to host successfully.</pre>
Nei log di Nagios troveremo:
<pre>nagios: Warning:Â  Passive check result was received for service 'pippo' on host 'hostAcaso', but the host could not be found!</pre>
Funziona! Non fatevi spaventare dal <em>warning</em>: Nagios ha ricevuto il check ma non ha nessun host corrispondente nella sua configurazione. Niente di male, glielo spiegheremo più tardi.

Possiamo quindi configurare Nagios per accettare i check passivi. Per farlo andiamo nel server e inseriamo nel file <em>etc/objects/templates.cfg</em> il template per un servizio che accetta sono check passivi:
<pre>define service{
 nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  passive-service
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  generic-service
 active_checks_enabledÂ Â Â Â Â Â Â Â Â Â  0
 passive_checks_enabledÂ Â Â Â Â Â Â Â Â  1
 flap_detection_enabledÂ Â Â Â Â Â Â Â Â  0
 registerÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  0
 is_volatileÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  0
 check_periodÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  24x7
 max_check_attemptsÂ Â Â Â Â Â Â Â Â Â Â Â Â  1
 normal_check_intervalÂ Â Â Â Â Â Â Â Â Â  5
 retry_check_intervalÂ Â Â Â Â Â Â Â Â Â Â  1
 check_freshnessÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  0
 contact_groupsÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  admins
 notification_optionsÂ Â Â Â Â Â Â Â Â Â Â  w,u,c,r
 stalking_optionsÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â  w,c,u
 notification_intervalÂ Â Â Â Â Â Â Â Â Â  120
 check_commandÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  check_dummy!0
}</pre>
Inseriamo poi nel file <em>etc/objects/commands.cfg</em> la definizione del comando <em>check_dummy</em>:
<pre>define command{
 command_nameÂ Â Â  check_dummy
 command_lineÂ Â Â  $USER1$/check_dummy $ARG1$
}</pre>
Fatto questo possiamo inserire un check di prova in un host:
<pre>define service{
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  passive-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  hostCheEsiste
 service_descriptionÂ Â Â Â Â Â Â Â Â Â Â Â  TestMessage
}</pre>
Una volta riavviato Nagios vedremo questo servizio in stato pending. Modificando il file di prima con:
<pre>hostCheEsisteÂ Â Â  TestMessageÂ Â Â  0Â Â Â Â  Messaggio di OK</pre>
ed eseguendo nuovamente:
<pre>/usr/local/nagios/bin/send_nsca localhost -c /usr/local/nagios/etc/send_nsca.cfg &lt; test</pre>
possiamo mettere il servizio in stato di OK.

Per finire dobbiamo dire a Munin di chiamare Nagios quando qualcosa non va. Per farlo dobbiamo modificare il file <em>munin.conf</em> inserendo:
<pre>contacts nagios
contact.nagios.command /usr/local/nagios/bin/send_nsca -H localhost -c /usr/local/nagios/etc/send_nsca.cfg</pre>
Modificate le path secondo la vostra configurazione e inserite nel file <em>send_nsca.cfg</em> l'eventuale password per comunicare con NSCA.
<h2>Ma come funzionano in dettaglio gli avvertimenti di Munin?</h2>
Munin si basa su plugin e ognuno di essi ha dei limiti. Per vederli basta lanciare (in questo caso interrogo il plugin <strong>cpu</strong>):
<pre>munin-run cpu config</pre>
Nella risposta si possono individuare i limiti:
<pre>system.warning 60
system.critical 100</pre>
Tali limiti possono essere monitorati da munin-limits, un eseguibile che, per essere lanciato automaticamente, va inserito in crontab. Di base ne trovate una configurazione in <em>/etc/cron.d/munin</em> (se non c'è createlo). Io l'ho modificato così:
<pre>*/5 * * * *Â Â Â Â  munin if [ -x /usr/share/munin/munin-limits ]; then /usr/share/munin/munin-limits --force --contact nagios --contact old-nagios; fi</pre>
Quindi ogni 5 minuti fa il check e contatta Nagios per passargli il risultato.

L'ultima cosa da fare è adattare i limiti di ogni plugin secondo le proprie esigienze. Si possono definire in <em>munin.conf</em> per ogni host:
<pre>df._mapper_sda1_vm_root.warningÂ Â Â Â Â  0:90
df._mapper_sda1_vm_root.criticalÂ Â Â Â  0:95
df.notify_aliasÂ Â Â Â  Disk usage</pre>
La logica con cui vengono definiti i limiti è un po' cervellotica e dipende molto dal tipo di plugin. In questo caso ho usato <strong>df</strong> che controlla l'uso del disco.
Il limite di warning 0:90 viene superato se il limite è al di fuori di questo range (il range è 0:100). Ma a sua volta il limite critico è al di fuori del range 0:95. Il risultato è che il plugin entra in <strong>warning</strong> se la partizione è occupata tra il 90% e il 94% e in <strong>critical</strong> da 95% in sù.
Vi lascio divertire con gli altri plugin :)
<h2>Inseriamo in Nagios questi check</h2>
Ho già  mostrato prima come inserire un check passivo in un host, ovvero:
<pre>define service{
 useÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  passive-service
 host_nameÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â  hostCheEsiste
 service_descriptionÂ Â Â Â Â Â Â Â Â Â Â Â  TestMessage
}
</pre>
Per accettare un check passivo valido da Munin bisogna modificare <strong>service_description</strong> affinchè sia uguale al nome del servizio che definisce il plugin di Munin. Dato che hanno nomi non facilmente individuabili e che a volte contengono caratteri incompatibili con Nagios (ad esempio %) una cosa furba è rinominarli in <em>munin.conf</em> con <strong>.notify_alias</strong> (guardate qualche riga più in sù nel caso del <strong>df</strong>) e usare quell'alias in Nagios.

A questo punto la teoria è finita e non rimane altro da fare che iniziare a scrivere le definizioni dei check in Nagios e le configurazioni dei plugin in Munin, buon lavoro!