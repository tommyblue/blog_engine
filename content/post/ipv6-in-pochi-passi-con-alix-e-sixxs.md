+++
author = "Tommaso Visconti"
categories = ["informatica", "software libero", "ipv6", "how-to", "alix", "sixxs"]
date = 2011-08-03T12:41:51Z
description = ""
draft = false
slug = "ipv6-in-pochi-passi-con-alix-e-sixxs"
tags = ["informatica", "software libero", "ipv6", "how-to", "alix", "sixxs"]
title = "IPv6 in pochi passi con ALIX e SixXS"

+++

Come ormai saprete (<a href="http://www.tommyblue.it/2010/05/25/endian-firewall-su-alix/">1</a> - <a href="http://www.tommyblue.it/2010/02/12/costruirsi-un-sistema-di-monitoraggio-casalingo-con-nagios-parte-1/">2</a>) ho un debole per gli embedded ALIX di <a title="PC Engines" href="http://pcengines.ch/" target="_blank">PcEngines</a>. In questo caso userò una scheda <a href="http://pcengines.ch/alix2d13.htm" target="_blank">2d13</a> con <strong>RTC</strong>, indispensabileÂ perchéÂ se il vostro orologio non è sincronizzato con quello del broker IPv4-IPv6 (Â±30 secondi) non avrete la connessione IPv6!

Come da tradizione il sistema operativo è <a href="http://linux.voyage.hk/" target="_blank">Debian Voyage</a>, ma tutta la procedura può comunque essere applicata ad una qualsiasi macchina con installato un os <em>Debian-based</em> (a meno di qualche piccola modifica). Per altri sistemi operativi guardate la <a title="Wiki di SixXS" href="https://www.sixxs.net/wiki/" target="_blank">wiki di SixXS</a>.
<h2>SixXS</h2>
Il primo passo è, per l'appunto, quello di <a href="http://www.sixxs.net/signup/create/" target="_blank">registrarsi su SixXS</a> e richiedere un account.Â La registrazione, prima di essere accettata, deve essere verificata manualmente quindi probabilmente potrebbe passare qualche giorno (nel mio caso ci sono voluti pochi minuti).

Una volta ottenuti i dati di accesso bisogna richiedere un tunnel. In questa guida coprirò la configurazione di un tunnel heartbeat con Aiccu. Anche la richiesta del tunnel richiede approvazione, quindi in attesa possiamo configurare il sistema (una volta approvato il tunnel basta inserirne il nome in <em>/etc/aiccu.conf</em> e gli ip in <em>/etc/network/interfaces</em>).
<h2>AICCU</h2>
Come premesso il sistema deve avere l'ora corretta con uno scarto massimo di 30 secondi, altrimenti AICCU non stabilisce la connessione. Nel più semplice dei casi per farlo basta installare il pacchetto <strong>ntp</strong>. AICCU logga in <em>/var/log/syslog</em>, ecco il tipico errore per problemi di sincronizzazione:

```prettyprint lang-bash

~# cat /var/log/syslog | grep aiccu

Apr 28 08:50:19 voyage aiccu[1731]: sock_getline() : "200 Client Identity accepted"
Apr 28 08:50:19 voyage aiccu[1731]: sock_printf() Â : "get unixtime"
Apr 28 08:50:19 voyage aiccu[1731]: sock_getline() : "200 1312374039"
Apr 28 08:50:19 voyage aiccu[1731]: The clock is off by 355469420 seconds, use NTP to sync it!
Apr 28 08:50:19 voyage aiccu[1731]: sock_printf() Â : "QUIT Aborting: Clock is off by 355469420 seconds "
Apr 28 08:50:19 voyage aiccu[1731]: Couldn't retrieve first tunnel for the above reason, aborting

```


Una volta sincronizzato l'orario si può procedere installando il pacchetto <strong>aiccu</strong><em> </em>. All'installazione vi verranno chiesti i dati di accesso a SixXS. Oltre a questo ho scommentato soltanto due righe in <em>/etc/aiccu.conf</em>, riporto tutto il file:

```prettyprint lang-bash

username MY_USERNAME
password MY_PASSWORD
protocol tic
server tic.sixxs.net
ipv6_interface sixxs
tunnel_id MY_TUNNEL
verbose false
daemonize true
automatic true
requiretls false
makebeats true

```


Basta adattare le variabili <em>username</em>, <em>password</em> e <em>tunnel_id</em> (tutti dati che vi devono essere dati da SixXS) e il gioco è fatto.
Molte informazioni le potete trovare anche nella wiki di SixXS: <a href="http://www.sixxs.net/wiki/Aiccu" target="_blank">http://www.sixxs.net/wiki/Aiccu</a>
<h2>Interfaccia di rete</h2>
Quando il tunnel ci verrà  attivato potremo configurare l'interfaccia, nello specifico inserendo questa configurazione in <em>/etc/network/interfaces</em> (utilizzando i dati che abbiamo ottenuto):

```prettyprint lang-bash

auto sixxs
iface sixxs inet6 v4tunnel
address MY_IPV6_IP
netmask 64
endpoint 213.254.12.34
ttl 64
up ip link set mtu 1280 dev sixxs
up ip route add default via MY_IPV6_GATEWAY dev sixxs

```


L'IPv4 dell'endpoint è quello italiano, ad ogni modo nella mail di conferma attivazione del tunnel c'è scritto tutto. Il vostro indirizzo IP e quello del gateway differiscono soltanto per l'ultima cifra: <strong>:1</strong> per il gateway e <strong>:2</strong> per il vostro IP.
<h2>Test IPv6</h2>
Terminati questi passaggi il nostro IPv6 dovrebbe essere pronto. Riavviamo AICCU e la rete (<em>/etc/init.d/networking restart</em>) e testiamo il tutto pingando (occhio, ci vuoleÂ <em>ping6</em>) il gateway IPv6.
Per ulteriore prova si può visitare ï»¿Â laÂ home page di <a title="SixXS" href="http://www.sixxs.net/" target="_blank">SixXS</a> dove un blocchetto verde ci accoglierà  con un festante <strong>"You've got IPv6!"</strong>.
Se siete a terminale e volete testare qualche sito in IPv6 fate attenzione che <strong>lynx</strong> supporta IPv6 mentre <strong>links2</strong> no.
<h2>Subnet, routing e assegnazione IP</h2>
Ora che abbiamo un IPv6 e lo usiamo per navigare da un pc, è giunto il momento di ottenere una subnet <strong>/48</strong> per poter assegnare un IPv6 ad ogni nostro apparato (ovvero ai nostri<strong> <a title="IPv6 Subnet Size Reference Table" href="http://www.potato-people.com/blog/2009/02/ipv6-subnet-size-reference-table/" target="_blank">1.208.925.819.614.629.500.000.000</a> </strong>apparati).

Come al solito il primo passo è richiedere a SixXS una subnet. Una volta ottenuta la rete /48, seguendo la <a href="https://www.sixxs.net/wiki/Installing_a_Subnet" target="_blank">guida nella wiki di Sixxs</a>, andiamo a configurare una /64 per la nostra rete.
Assegniamo staticamente uno di questi indirizzi in <em>/etc/network/interfaces</em>:

```prettyprint lang-bash

iface eth0 inet6 static
address MY_IP_FROM_SUBNET
netmask 64

```


Riavviata la rete, il nostro ALIX avrà  un secondo IPv6 (oltre a quello del tunnel). Per permettere il routing e l'advertising degli indirizzi ip usiamoÂ <strong>radvd</strong>: non si tratta di un DHCPv6 (al momento non esiste un DHCPv6 veramente funzionante) ma di un router IPv6 che periodicamente invia pacchetti multicast di Router Advertisement per permettere l'autoconfigurazione degli apparati di rete utilizzando gli ip della nostra subnet.
Dopo aver installato il pacchetto <strong>radvd</strong> bisogna creare il file <em>/etc/radvd.conf</em> con il seguente contenuto:

```prettyprint lang-bash

interface eth0{
  AdvSendAdvert on;
  prefix MY_IP_FROM_SUBNET/64
  {
    AdvOnLink on;
    AdvAutonomous on;
    AdvRouterAddr on;
  };
};

```


Avviamo radvd e abilitiamo il forwarding:

```prettyprint lang-bash

echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.forwarding=1" >> /etc/sysctl.conf
sysctl -p

```


Se tutto è andato come doveva le macchine nella vostra rete dovrebbero ottenere un indirizzo IPv6 (parlo di Mac e Linux, per Windows arrangiatevi.. :) e navigare IPv6.
Provate ad aprire il sito SixXS per averne conferma:

<img class="aligncenter size-full wp-image-1223" title="You've got IPv6!" src="/uploads/2011/08/Youve-got-ipv6.png" alt="" width="219" height="78" />
<h2>Firewall IPv6</h2>
Una cosa che ben presto si capisce di IPv6 è che le tanto odiate NAT in certi casi facevano comodo. Uno di questi è che un IP privato era <strong>privato</strong>. Con IPv6 quasi tutto è pubblico e quindi un firewall è indispensabile.

Ho scritto un breve script per <strong>ip6tables</strong> prendendo spunto dalla wiki si SixXS, dopo averlo personalizzato (dovete settare qualche IP) basta metterlo in <em>/etc/init.d</em> e aggiungerlo al runlevel di default (<em>update-rc.d firewall-ipv6 defaults</em>):

```prettyprint lang-bash

#! /bin/bash

### BEGIN INIT INFO
# Provides:             firewall-ipv6
# Required-Start:       $remote_fs $syslog
# Required-Stop:        $remote_fs $syslog
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    IPTables-based IPv6 firewall
### END INIT INFO

set -e

# /etc/init.d/firewall-ipv6: start and stop the ip6tables firewall

IP6="/sbin/ip6tables"

# L'indirizzo IP di questa macchina
THIS_HOST="2001:1418:AAAA:AAAA::2"

# La subnet assegnata da SixXS
SUBNET_PREFIX="2001:1418:BBBB::/48"

stop_firewall() {
# First, delete all:
$IP6 -F
$IP6 -X

$IP6 -P INPUT   ACCEPT
$IP6 -P FORWARD ACCEPT
$IP6 -P OUTPUT  ACCEPT
}

start_firewall() {
stop_firewall

# Allow anything on the local link
$IP6 -A INPUT  -i lo -j ACCEPT
$IP6 -A OUTPUT -o lo -j ACCEPT

# Allow anything out on the internet
$IP6 -A OUTPUT -o sixxs -j ACCEPT

# Allow the localnet access us:
$IP6 -A INPUT    -i eth0   -j ACCEPT
$IP6 -A OUTPUT   -o eth0   -j ACCEPT

# Filter all packets that have RH0 headers:
$IP6 -A INPUT -m rt --rt-type 0 -j DROP
$IP6 -A FORWARD -m rt --rt-type 0 -j DROP
$IP6 -A OUTPUT -m rt --rt-type 0 -j DROP

# Allow Link-Local addresses
$IP6 -A INPUT -s fe80::/10 -j ACCEPT
$IP6 -A OUTPUT -s fe80::/10 -j ACCEPT

# Allow multicast
$IP6 -A INPUT -s ff00::/8 -j ACCEPT
$IP6 -A OUTPUT -s ff00::/8 -j ACCEPT

# Allow ICMPv6 everywhere
$IP6 -I INPUT  -p icmpv6 -j ACCEPT
$IP6 -I OUTPUT -p icmpv6 -j ACCEPT
$IP6 -I FORWARD -p icmpv6 -j ACCEPT

# Allow forwarding
$IP6 -A FORWARD -m state --state NEW -i eth0 -o sixxs -s $SUBNET_PREFIX -j ACCEPT
$IP6 -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH verso questa macchina
$IP6 -A INPUT -i sixxs -p tcp -d $THIS_HOST --dport 22 -j ACCEPT

# Accesso a macchine della rete
#$IP6 -A FORWARD -i sixxs -p tcp -d $IP_DA_RAGGIUNGERE --dport $PORTA_DA_RAGGIUNGERE -j ACCEPT

# Set the default policy
$IP6 -P INPUT   DROP
$IP6 -P FORWARD DROP
$IP6 -P OUTPUT  ACCEPT
}

test -x $IP6 || exit 0

set -e

case "$1" in
start)
echo -e "Starting Firewall"
stop_firewall
start_firewall
;;
stop)
echo -e "Stopping Firewall"
stop_firewall
;;
restart)
echo -e "Restarting Firewall"
stop_firewall
start_firewall
;;
*)
N=/etc/init.d/$NAME
echo "Usage: $N {start|stop|restart}" >&2
exit 1
;;
esac

exit 0

```


Per essere sicuri che il firewall funzioni si può usare questa applicazione web:Â <a title="Tim's Free IPv6 TCP Port Scanner (Firewall Tester)" href="http://ipv6.chappell-family.com/ipv6tcptest/" target="_blank">http://ipv6.chappell-family.com/ipv6tcptest/</a>. Se tutto va bene il risultato dovrebbe essere questo:

<a href="/uploads/2011/08/Firewall-check.png" rel="prettyPhoto"><img class="aligncenter size-medium wp-image-1224" title="IPv6 firewall check" src="/uploads/2011/08/Firewall-check-300x144.png" alt="" width="300" height="144" /></a>