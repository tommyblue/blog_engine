+++
author = "Tommaso Visconti"
categories = ["riflessioni", "povertà ", "ricchezza"]
date = 2009-11-11T23:35:31Z
description = ""
draft = false
slug = "universi-paralleli"
tags = ["riflessioni", "povertà ", "ricchezza"]
title = "Universi Paralleli"

+++

<p style="text-align: center;"><a href="/uploads/2009/11/parallelo.jpg"><img class="aligncenter Come <a href="http://www.tommyblue.it/2009/10/08/unicorn-rack-http-server-for-unix-and-fast-clients/">avevo promesso</a> avrei dedicato del tempo ad indagare circa le possibilità  offerte da <a href="http://unicorn.bogomips.org/" target="_blank">Unicorn</a> per il deploy delle applicazioni Ruby On Rails. Di seguito un riepilogo di quel che ho fatto per configurare il nuovo deploy di <a href="http://kickin.kreations.it" target="_blank">Kickin'</a> utilizzando Unicorn, Nginx e Apache.
<h3>Unicorn</h3>
L'installazione di Unicorn si fa "di tacco" (per una descrizione più dettagliata <a href="http://www.tommyblue.it/2009/10/08/unicorn-rack-http-server-for-unix-and-fast-clients/">leggete il vecchio post</a>), basta un semplice:
<pre>gem install unicorn</pre>
Per le applicazioni anzichè farle rispondere su socket tcp ho deciso di utilizzare le socket Unix (posiziondole in /tmp), quindi il comando completo (da lanciare dentro la root dell'applicazione Rails) è:
<pre>unicorn_rails -D -E production -l /tmp/kickin.kreations.it.sock</pre>
ovvero lancio unicorn in modalità  demone (<strong>-D</strong>), con l'environment production (<strong>-E production</strong>) e sulla socket /tmp/kickin.kreations.it.sock (<strong>-l /tmp/kickin.kreations.it.sock</strong>). Per la lista completa delle opzioni c'è il solito <strong>-h</strong> :)

<!--more-->Per rendere tutto automatizzato ho creato (in stile apache2) la cartella <strong>/etc/unicorn</strong> con dentro le cartelle <strong>sites-available</strong> e <strong>sites-enabled</strong>. Il contenuto di <strong>/etc/unicorn/sites-available/kickin.kreations.it</strong> è:
<pre>#!/bin/bash
cd /var/www/tommyblue/kickin.kreations.it
su tommyblue -c "unicorn_rails -D -E production -l /tmp/kickin.kreations.it.sock"</pre>
Quindi il file <strong>/etc/init.d/unicorn_rails</strong>:
<pre>#! /bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/unicorn_rails
NAME=unicorn_rails
DESC=unicorn_rails
SITES=/etc/unicorn/sites-enabled
test -x $DAEMON || exit 0
set -e
start_instances() {
Â Â  for i in `ls $sites`; do
Â Â  echo -n "Starting $i"
Â Â  $SITES/$i
Â Â  done
}
case "$1" in
Â  start)
Â Â Â  start_instances;
Â Â Â  ;;
Â  stop)
Â Â Â  echo -n "Stopping $DESC: "
Â Â Â  killall $NAME
Â Â Â  ;;
Â  *)
Â  Â  N=/etc/init.d/$NAME
Â Â Â  echo "Usage: $N {start|stop}" &gt;&amp;2
Â Â Â  exit 1
Â Â Â  ;;
esac
exit 0</pre>
Ed ho quindi aggiunto lo script ai runlevel:
<pre>update-rc.d unicorn_rails defaults 99</pre>
Adesso ci si può sbizzarrire a lanciare e fermare i siti
<h3>Nginx</h3>
Installato nginx (<strong>apt-get install nginx</strong>) si passa a configurarlo. Io ho eliminato il sito di default e ho creato solo i files che mi interessavano (tanto la porta 8080 è chiusa dall'esterno quindi non ho problemi riguardo al visitare siti "imprevisti"). Ecco <strong>/etc/nginx/sites-available/kickin.kreations.it</strong>:
<pre>upstream backend {
Â  server unix:/tmp/kickin.kreations.it.sock;
}
server {
Â  listenÂ Â  8080;
Â  server_nameÂ  kickin.kreations.it;
Â  access_logÂ  /var/log/nginx/kickin.kreations.it.access.log;
Â  location / {
Â Â Â  proxy_pass http://backend;
Â Â Â  proxy_redirect off;
Â Â Â  proxy_set_headerÂ Â Â Â Â Â Â  HostÂ Â Â  $host;
Â Â Â  proxy_set_headerÂ Â Â Â Â Â Â  X-Real-IPÂ Â Â Â Â Â  $remote_addr;
Â Â Â  proxy_set_headerÂ Â Â Â Â Â Â  X-Forwarded-For $proxy_add_x_forwarded_for;
Â Â Â  rootÂ Â  /var/www/nginx-default;
Â Â Â  indexÂ  index.html index.htm;
Â Â Â  }
Â  error_pageÂ Â  500 502 503 504Â  /50x.html;
Â  location = /50x.html {
Â  rootÂ Â  /var/www/nginx-default;
Â  }
}</pre>
Come si vede dalla configurazione il backend utilizzato è la socket unix creata con unicorn e nginx risponde sulla porta 8080. Collegandosi al sito sulla porta 8080 (supponendo che il vostro server abbia tale porta accessibile dall'esterno) potete già  constatare la riuscita del deploy. Se poi, diversamente dal mio caso, non avete apache che risponde sulla 80, vi basterà  far rispondere nginx su tale porta e il gioco è fatto.
<h3>Apache</h3>
Se invece è apache che risponde sulla porta 80 è necessario questo ultimo passaggio. Innanzitutto bisogna attivare mod_proxy con:
<pre>a2enmod proxy</pre>
e quindi effettuare il reload di apache. Quindi si passa alla configurazione del sito, ecco <strong>/etc/apache2/sites-available/kickin.kreations.it</strong> (ho eliminato le righe non rilevanti):
<pre>&lt;VirtualHost *:80&gt;
Â  ServerName kickin.kreations.it
Â  ProxyRequests off
Â  ProxyPreserveHost On
Â  &lt;Proxy *&gt;
Â Â Â  Order deny,allow
Â Â Â  Allow from all
Â  &lt;/Proxy&gt;
Â  ProxyPass / http://127.0.0.1:8080/
Â  ProxyPassReverse / http://127.0.0.1:8080/
&lt;/VirtualHost&gt;</pre>
Una volta attivato il sito (con <strong>a2ensite</strong>), <a href="http://kickin.kreations.it" target="_blank">http://kickin.kreations.it</a> è disponibile e funzionante!
<h3>Conclusioni</h3>
Sebbene effettuare il deploy con Unicorn non sia ancorà  così agevole (e, a quanto dicono gli sviluppatori, ancora neanche troppo stabile, la versione è la 0.94.0) il risultato è veramente strabiliante. Non ho ancora provato dei test intensivi, ma la sensazione è di applicazioni molto più reattive e addirittura la generazione di un pdf che con Passenger impiegava circa 2 minuti con Unicorn viene generato in una <strong>ventina di secondi</strong>!

Termino segnalando <a href="http://rainbows.rubyforge.org/" target="_blank">Rainbows! Unicorn for sleepy apps and slow clients</a>, che proverò a breve :)