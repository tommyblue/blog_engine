+++
author = "Tommaso Visconti"
categories = ["informatica"]
date = 2007-01-19T22:34:20Z
description = ""
draft = false
slug = "hacking-della-fonera"
tags = ["informatica"]
title = "Hacking della Fonera"

+++

<img id="image12" src="/uploads/2007/01/fonera.jpg" alt="La Fonera" />
Da quasi 24 ore sono un felice possessore della Fonera.
Chi non fosse a conoscenza del Movimento Fon può leggerne qui i dettagli:
<a href="http://it.fon.com/">http://it.fon.com/</a>
<a href="http://blog.fon.com/it/">http://blog.fon.com/it/</a>
In 2 parole i possessori della Fonera condividono la loro connessione Internet con gli altri Foneros, divisi in Linus (chi condivide la propria connessione e può accedere liberamente a qualunque rete FON) e Bill (chi non condivide ma sfrutta solo le connessioni dei Linus).
Potete vedere la posizione di tutte le Fonere nel mondo da <a href="http://maps.fon.com/">qui</a>.

Arriviamo al punto:
La Fonera è un access point con software basato su <a href="http://openwrt.org/">OpenWRT</a> ma con firmware blindato dalla FON.
Grazie alla sua interfaccia web è possibile configurare molti parametri, ma non si può comunque avere pieno controllo del device.
Una grossa mancanza, soprattutto per noi italiani, è l'impossibilità  di gestire i log dei Foneros che usano il nostro punto d'accesso alla rete FON (potete leggere <a href="http://punto-informatico.it/p.aspx?id=1749773">Fon completa la mutazione</a> di Marco Calamari su Punto Informatico).

Ma vediamo cosa invece si può fare.
Un firmware, per poter essere installato, deve essere firmato digitalmente da FON. Quindi sembra impossibile poterlo sostituire.
Nel momento in cui attaccate la Fonera alla vostra rete essa otterrà  un IP dal vostro server DHCP (se presente) e si collegherà  a download.fon.com per ottenere l'ultimo firmware disponibile.
Come standard l'accesso ssh è negato, ma dei colleghi smanettoni sono riusciti in vari modi ad ottenere un accesso.
Inizialmente solo aprendo l'AP e collegando una porta seriale (<a href="http://blog.unlugarenelmundo.es/2006/11/02/habilitando-acceso-por-ssh-a-la-fonera/">1</a> - <a href="http://jauzsi.hu/2006/10/13/inside-of-the-fonera">2</a>), con gli ultimi sviluppi basta uno script in perl per ottenere il controllo della Fonera.

Iniziamo.
La cosa fondamentale è non attaccare subito la Fonera ad internet, in quel caso scaricherebbe immediatamente il nuovo firmware 0.7.1-2 del 3 Gennaio 2007 ed ogni successiva operazione potrebbe essere compromessa.
Dico potrebbe perché l'utente BiGAlex nel post di <a href="http://www.andreabeggi.net/2006/11/05/hacking-de-la-fonera/">Andrea Beggi</a> sostiene che resettando la Fonera (premendo per 30 secondi l'apposito bottone) e poi tenendola senza alimentazione (per qualche ora) essa torna al firmware originale.

Attaccate invece l'alimentazione al AP e connettetevi alla rete MyPlace utilizzando il numero di serie come password WPA. Otterrete l'indirizzo IP 192.168.10.2. Col browser potete aprire l'url 192.168.10.1 per raggiungere l'interfaccia web di controllo della Fonera. Da qui potete controllare la versione del firmware (nel mio caso 0.7.1-1).

Adesso utilizzate invece la connessione via cavo ethernet tra il vostro pc e la Fonera. Dato che la sua impostazione base è quella di cercare di ottenere un IP da un server DHCP, non trovandolo si imposterà  con l'IP 169.254.255.1. Voi assegnate alla vostra interfaccia di rete 169.254.255.2 e sarete in grado di dialogare con la Fonera (provate con un ping).

Non resta quindi che scaricare lo script in perl <a href="http://stefans.datenbruch.de/lafonera/scripts/fondue.pl">fondue.pl</a> per aprire la porta 22 e lanciare il demone ssh. Il comando è
<div id="code">
<code>$ echo -e '/usr/sbin/iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT\n/etc/init.d/dropbear' | perl fondue.pl 169.254.255.1 admin</code>
</div>

<b>Nota bene</b>
Lo script richiede il modulo Perl WWW::Mechanize, installabile con 
<div id="code"><code>perl -MCPAN -e 'install WWW::Mechanize'</code></div>

<strong>Attenzione</strong>
Ho avuto dei problemi con lo script in perl, mi veniva restituito l'errore
<div id="code"><code>Invalid # of args for overridden credentials() at fondue.pl line 25</code></div>
Per correggerlo è stato sufficiente cambiare (alla riga 25, appunto)
<div id="code">
<code># admin password
$browser->credentials($ip,"admin",$password);</code>
</div>
in
<div id="code">
<code># admin password
$browser->credentials("admin",$password);</code>
</div>
Ed ecco il risultato
<div id="code">
<code>$ echo -e '/usr/sbin/iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT\n/etc/init.d/dropbear' | perl fondue.pl 169.254.255.1 admin
By your command...
Injecting command Â»/usr/sbin/iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPTÂ«...
Injecting command Â»/etc/init.d/dropbearÂ«...
Code has been injected.
</code>
</div>
Non resta che effettuare il login, la password è <code>admin</code>
<div id="code">
<code>$ ssh root@169.254.255.1
The authenticity of host '169.254.255.1 (169.254.255.1)' can't be established.
RSA key fingerprint is b5:ea:84:a9:9e:b6:7c:c9:93:55:15:f4:ba:8e:a9:f4.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '169.254.255.1' (RSA) to the list of known hosts.
root@169.254.255.1's password:
</code>
<code>
BusyBox v1.1.3 (2006.11.21-19:49+0000) Built-in shell (ash)
Enter 'help' for a list of built-in commands.
 _______  _______  _______
|   ____||       ||   _   |
|   ____||   -   ||  | |  |
|   |    |_______||__| |__|
|___|
</code><code>
 Fonera Firmware (Version 0.7.1 rev 1) -------------
  *
  * Based on OpenWrt - http://openwrt.org
  * Powered by FON - http://www.fon.com
 ---------------------------------------------------
root@OpenWrt:~#</code>
</div>
Adesso che abbiamo ottenuto l'accesso ssh dobbiamo far si che sia stabile.
Quindi rinominiamo il file di avvio del demone <code>dropbear</code> in modo che all'avvio venga eseguito
<div id="code"><code>mv /etc/init.d/dropbear /etc/init.d/S50dropbear</code></div>
e modifichiamo il firewall aprendo di default le connessioni in ingresso sulla porta 22.
Per farlo utilizziamo <code>vi</code>, presente nel router, e modifichiamo il file <code>/etc/firewall.user</code>, in particolare le righe
<div id="code">
<code># iptables -t nat -A prerouting_rule -i $WAN -p tcp --dport 22 -j ACCEPT
# iptables -A input_rule -i $WAN -p tcp --dport 22 -j ACCEPT</code>
</div>
devono essere scommentate
<div id="code">
<code>iptables -t nat -A prerouting_rule -i $WAN -p tcp --dport 22 -j ACCEPT
iptables -A input_rule -i $WAN -p tcp --dport 22 -j ACCEPT</code>
</div>
L'ultimo passo prima di poter attaccare la Fonera ad internet ed usarla è impedire che la FON possa fargli eseguire del suo codice.
Quindi modifichiamo il file <code>/bin/thinclient</code> commentando l'ultima riga
<div id="code">
<code>### Don't execute code from FON
# . /tmp/.thinclient.sh</code>
</div>
e già  che ci siamo cambiamo anche la password di root, altrimenti chiunque può accedervi.

Questo è quanto, la durata dell'intero processo si aggira sui 10 minuti, se volete potete leggere le guide da cui ho preso spunto, di  <a href="http://stefans.datenbruch.de/lafonera/">Stefans Datenbruch</a> e  <a href="http://www.zarrelli.org/blog/index.php/2006/11/06/aprire-ssh-su-la-fonera-senza-aprirla/">Zarrelli</a>.

Happy Hacking...