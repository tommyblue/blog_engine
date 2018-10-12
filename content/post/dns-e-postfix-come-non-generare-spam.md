+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "dns", "postfix", "domainkeys", "reverse dns", "spf", "smtp", "spam", "dkim"]
date = 2010-01-18T00:02:50Z
description = ""
draft = false
slug = "dns-e-postfix-come-non-generare-spam"
tags = ["informatica", "how-to", "dns", "postfix", "domainkeys", "reverse dns", "spf", "smtp", "spam", "dkim"]
title = "DNS e Postfix: come non generare \"spam\""

+++

<strong>Edit (29/01/2010): Aggiunte una correzione per far funzionare la firma DKIM su server di relay</strong>

Ho recentemente configurato alcuni server per l'invio di email. Parte del lavoro ha riguardato la corretta configurazione di Postfix e del server DNS per evitare che le email inviate venissero rilevate come spam.
<em>In una diversa guida spiegherò come ottimizzare la configurazione di Postfix per grandi quantità  di email (â‰¥1.000.000/mese). Dato che già  in molti me lo hanno chiesto: no, non si tratta di server per l'invio di spam, ma server per il <a href="http://en.wikipedia.org/wiki/E-mail_marketing" target="_blank">mail marketing</a> (quando il servizio sarà  pubblico potrò tranquillamente rivelarne il nome).
</em>

La configurazione ha riguardato <strong>tre punti principali</strong>:
<ul>
	<li>Impostazione del record AÂ e del reverse address</li>
	<li>Impostazione di SPF</li>
	<li>Configurazione di DKIM e DomainKeys</li>
</ul>
<!--more-->
<h3>Record AÂ e Reverse Address</h3>
Per iniziare, il server SMTP deve avere un <strong>record DNS di tipo A</strong> associato. Quindi, ad esempio:
<pre>mailer1.mydomain.com IN A 12.34.56.78</pre>
Tale impostazione è a carico del proprietario del dominio <em>mydomain.com</em> (ovvero: voi).
Allo stesso tempo bisogna impostare il <strong>DNS inverso</strong> per una corretta risoluzione: infatti il server che riceverà  una mail dall'ip <em>12.34.56.78,</em> che dice di essere <em>mailer1.mydomain.com</em>, vorrà  avere riscontro di tale associazione <strong>IP&lt;=&gt;Dominio</strong>. Effettuerà  quindi una risoluzione DNS inversa che, nel caso in esempio, dovrà  restituire <em>mailer1.mydomain.com</em>. Questa configurazione è a carico del fornitore della connettività  e dell'ip, generalmente coloro che vi forniscono l'hosting.

Per verificare la corretta configurazione basta usare <strong>dig</strong>:
<pre>~$ dig +short mailer1.mydomain.com
12.34.56.78Â 

~$ dig +short -x 12.34.56.78
mailer1.mydomain.com.</pre>
<h3>Sender Policy Framework</h3>
<address><strong>Sender Policy Framework</strong> abbreviato inÂ <strong>SPF</strong> è un metodo per limitare gli abusi del nome del mittente nei messaggi diÂ posta elettronica. Si tratta di un protocollo tramite il quale è possibile definireÂ <em>da dove</em> viene spedita la posta elettronica per una certa classe di mittenti. (WikiPedia)</address>Sebbene non nuovissimo, SPF è largamente utilizzato e una sua corretta configurazione permette già  una certa sicurezza nel fatto che le mail inviate non vengano riconosciute come spam. Si tratta semplicemente di impostare un record DNS di tipo TXT indicante quali server sono autorizzati ad inviare email per tale dominio.

Le configurazioni possibili sono molte (potete consultarle nell'<a href="http://tools.ietf.org/html/rfc4408" target="_blank">RFC 4404</a>), nel nostro caso il record potrebbe essere:
<pre>v=spf1 mx ip4:12.34.56.78 ~all</pre>
Oltre alla versione (<strong>v=spf1</strong>), indica che gli host con associato un record MX per il dominio, oltre al server con ip <em>12.34.56.78</em>, possono inviare email. Inoltre indica, con <strong>~all</strong>, che tale configurazione comprende tutti i possibili host che inviano email per il dominio.

Potete utilizzare <a href="http://old.openspf.org/wizard.html" target="_blank">questo tool</a> per creare i vostri record SPF.
<h3>DKIM e DomainKeys</h3>
DomainKeys e DKIM sono due sistemi per la verifica del mittente nel dominio e l'integrità  del messaggio. Entrambi utilizzano il sistema a chiave pubblica/privata: la chiave pubblica è distribuita in un record DNS e la chiave privata viene utilizzata dal server SMTP per firmare l'email prima del suo invio.Â <strong>DomainKeys</strong> è nata in casa <strong>Yahoo</strong> (che, tra i grandi ISP, è l'unica che lo utilizza, a quanto ne so), <strong>DKIM</strong> (<strong><a href="http://en.wikipedia.org/wiki/DomainKeys_Identified_Mail" target="_blank">DomainKeys Identified Mail</a></strong>) è la sua evoluzione.

Nel mio caso uno tra i requisiti del server è quello di permettere la personalizzazione dei campi <em>From</em> e <em>Reply-To</em> mentre il collegamento col server di invio è rappresentato dal campoÂ <em>Return-Path</em> valorizzato con il dominio del server. Data la difficoltà  nell'impostare DomainKeys con tale configurazione e data la sua scarsa diffusione, mi sono intanto limitato alla configurazione di DKIM per la quale ho seguito <a href="https://help.ubuntu.com/community/Postfix/DKIM" target="_blank">questa guida</a> con alcune modifiche.

Si inizia installando <strong>dkim-filter</strong>:
<pre>~$ sudo apt-get install dkim-filter</pre>
e generando le chiavi per il server con l'apposito tool
<pre>~$ dkim-genkey -s mailer1 -d mydomain.com -t</pre>
Dopo questo comando nel file <strong>mailer1.private</strong> vi sarà  la chiave privata mentre nel file <strong>mailer1.txt</strong> una possibile configurazione per il record DNS:
<pre>mailer1._domainkey IN TXT "v=DKIM1; g=*; k=rsa; t=y; p=MIGfMA0GC[...cut...]8FsXOPbuUQIDAQAB" ; ----- DKIM mailer1 for mydomain.com</pre>
Sebbene questo record sia corretto, le opzioni sono molte e consiglio un'attenta lettura degli RFC (linkati sulla <a href="http://en.wikipedia.org/wiki/DomainKeys_Identified_Mail" target="_blank">pagina dedicata di WikiPedia</a>), in particolare potreste essere interessati a modificare "<strong>t=y;</strong>" in "<strong>t=;</strong>" dichiarando che il servizio di firma non è in fase di test. A tale record consiglio di aggiungerne un secondo, più generale:
<pre>_domainkey.mydomain.com. IN TXT "o=~"</pre>
che indica che non tutte le email generate dal dominio vengono firmate (l'alternativa è "<strong>o=-</strong>").

A questo punto si prosegue con la configurazione del file <strong>/etc/default/dkim-filter</strong>. Basta decommentare una delle righe che specificano un socket. Io ho scelto di utilizzare:
<pre>SOCKET="inet:20209@localhost"</pre>
Proseguiamo quindi con <strong>/etc/dkim-filter.conf.</strong> Riporto tutte le configurazioni fatte, ricordandovi che tale configurazione è studiata per permettere la personalizzazione dei campi From e Reply-To (e quindi una sorta di configurazione multidominio):
<pre>Syslog Â  Â  Â  Â  Â  Â  Â  Â  Â yes
SyslogSuccess Â  Â  Â  Â  Â  yes
UMask Â  Â  Â  Â  Â  Â  Â  Â  Â  022
UserID Â  Â  Â  Â  Â  Â  Â  Â  Â dkim-filter:dkim-filter
Socket Â  Â  Â  Â  Â  Â  Â  Â  Â inet:20209@localhost
Domain Â  Â  Â  Â  Â  Â  Â  Â  Â *
Selector Â  Â  Â  Â  Â  Â  Â  Â mailer1
AutoRestart Â  Â  Â  Â  Â  Â  yes
Background Â  Â  Â  Â  Â  Â  Â yes
Canonicalization Â  Â  Â  Â simple
DNSTimeout Â  Â  Â  Â  Â  Â  Â 5
Mode Â  Â  Â  Â  Â  Â  Â  Â  Â  Â sv
SignatureAlgorithm Â  Â  Â rsa-sha1
SubDomains Â  Â  Â  Â  Â  Â  Â no
X-Header Â  Â  Â  Â  Â  Â  Â  Â yes
Statistics Â  Â  Â  Â  Â  Â  Â /var/log/dkim-filter/dkim-stats
AllowSHA1Only Â  Â  Â  Â  Â  no
AlwaysAddARHeader Â  Â  Â  no
AutoRestartRate Â  Â  Â  Â  10/1h
Canonicalization Â  Â  Â  Â simple/simple
KeyList Â  Â  Â  Â  Â  Â  Â  Â  /etc/mail/dkim/keylist
MTA Â  Â  Â  Â  Â  Â  Â  Â  Â  Â  MSA
On-Default Â  Â  Â  Â  Â  Â  Â reject
On-BadSignature Â  Â  Â  Â  reject
On-DNSError Â  Â  Â  Â  Â  Â  tempfail
On-InternalError Â  Â  Â  Â accept
On-NoSignature Â  Â  Â  Â  Â accept
On-Security Â  Â  Â  Â  Â  Â  discard
PidFile Â  Â  Â  Â  Â  Â  Â  Â  /var/run/dkim-milter/dkim-milter.pid
RemoveOldSignatures Â  Â  yes</pre>
Il file <strong>/etc/mail/dkim/keylist</strong> contiene:
<pre>*:mydomain.com:/etc/mail/dkim/keys/mydomain.com/mailer1</pre>
mentre il file <strong>/etc/mail/dkim/keys/mydomain.com/mailer1</strong> contiene la chiave privata, ovvero il file <strong>mailer1.private</strong> precedentemente creato, spostato in una cartella adatta e con i giusti permessi:
<pre>~$ mv mailer1.private /etc/mail/dkim/keys/mydomain.com/mailer1
~$ chmod 600 /etc/mail/dkim/keys/mydomain.com/mailer1
~$ chown dkim-filter:dkim-filter /etc/mail/dkim/keys/mydomain.com/mailer1</pre>
Se il server di invio email riceverà  email da altri server (di cui è quindi un <em>relayhost</em>) sarà  necessario specificare quali sono i server "fidati". Quindi nel file <strong>/etc/dkim-filter.conf</strong> bisogna aggiungere:
<pre>InternalHosts Â  Â  Â  Â  Â  /etc/mail/dkim/trusted-hosts</pre>
e bisogna creare il file /<strong>etc/mail/dkim/trusted-hosts</strong> contenente (uno per linea) gli indirizzi ip dei server (attenzione che contenga anche l'indirizzo ip di localhost, <em>127.0.0.1</em>).

Per concludere è necessario configurare Postfix per firmare le email, aggiungendo nel file <strong>/etc/postfix/main.cf</strong>:
<pre>smtpd_milters = inet:localhost:20209
non_smtpd_milters = inet:localhost:20209
milter_protocol = 2
milter_default_action = accept</pre>
Adesso basta far partire i due demoni e si può provare ad inviare una email:
<pre>~$ sudo /etc/init.d/dkim-filter start
~$ sudo /etc/init.d/postfix start
~$ echo "Questa email è una prova" | mail -a "From: qualcosa@miodominio.it" -a "Reply-To: dilloame@dominio.it" -s "Email di test" recipient@dominioricevente.it -- -f mailer1@mydomain.com</pre>
In <strong>/var/log/mail.log</strong> potete verificare l'avvenuta firma:
<pre>Jan 18 00:26:35 mailer1 dkim-filter[21178]: XXXXXXXXXX "DKIM-Signature" header added</pre>
Se inviate la mail a un dominio <em>yahoo.com</em> o <em>gmail.com</em> potete verificare subito se la firma ha avuto successo. Ad esempio ecco l'header di una mail ricevuta da Yahoo:
<pre>Authentication-Results: mta1169.mail.mud.yahoo.com Â from=miodominio.it; domainkeys=neutral (no sig); from=mydomain.com; dkim=pass (ok)</pre>
Questa prima guida è conclusa. Spero di riuscire a trovare a breve una soluzione per la configurazione di DomainKeys in modo da poter integrare questo articolo