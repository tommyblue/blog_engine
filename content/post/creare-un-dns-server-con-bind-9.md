+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "bind"]
date = 2006-05-07T05:59:40Z
description = ""
draft = false
slug = "creare-un-dns-server-con-bind-9"
tags = ["informatica", "how-to", "bind"]
title = "Creare un DNS server con Bind 9"

+++

Quando digitate un indirizzo sul vostro browser: per esempio "www.google.it", la prima cosa che il browser fa è chiedere a qualcuno a che indirizzo IP corrisponde quel "google.it"... Questo qualcuno è proprio il server DNS di turno.

Un comando comodo per fare i vostri esperimenti con la risoluzione dei nomi è nslookup:
<div class="&quot;codice&quot;">#nslookup www.google.it

Server:         127.0.0.1
Address:        127.0.0.1#53

Non-authoritative answer:
www.google.it   canonical name = www.google.com.
www.google.com  canonical name = www.google.akadns.net.
Name:   www.google.akadns.net
Address: 66.102.11.99
Name:   www.google.akadns.net
Address: 66.102.11.104</div>
Le prime due righe che vediamo, ci dicono proprio l'indirizzo del server DNS che è stato usato per risolvere l'indirizzo (nel mio caso, 127.0.0.1 sono sempre io).
C'è scritto che la risposta che ci viene data non è autoritativa ovvero, il server DNS che è stato interrogato non è quello che gestisce google.it, ma conosce il suo indirizzo per "sentito dire" allora la risposta non è certa, perchè dall'ultima volta che l'indirizzo è stato interrogato l'indirizzo potrebbe essere stato cambiato (per ovviare a questo si mettono delle scadenze per la memoria brevi: TIME TO LIVE come vedremo dopo).
Le righe seguienti si commentano da sole, l'indirizzo viene risolto con due indirizzi IP per questioni di bilanciamento del carico: generalmente i browser si collegano al primo e scartano i rimanenti (ci pensa il server DNS a restituire gli IP con ordine casuale).
Quello che vogliamo fare è realizzare un server DNS sulla nostra Linux Box (Debian in particolare) in modo da avvantaggiarci di una cache nella risoluzione degli indirizzi che renderà  la navigazione piu' veloce (a volte molto più veloce, visto che ultimamente non è raro che i server DNS siano oberati di lavoro e rallentati).

Vediamo un esempio di miglioramento di prestazioni:
Faccio prima una richiesta per risolvere un indirizzo e ne misuro i tempi:
<div class="&quot;codice&quot;">#time nslookup www.isc.org

Server:         127.0.0.1
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   www.isc.org
Address: 204.152.184.88

real    0m0.361s
user    0m0.004s
sys     0m0.002s</div>
361ms per la prima richiesta (fatta al dns locale, che però non trovandola in cache la richiede al DNS del mio provider) e ci è andata anche abbastanza di lusso.
Ad una seconda richiesta dello stesso indirizzo questa volta bind conoscerà  già  la risposta e risponderà  più velocemente:
<div class="&quot;codice&quot;">#time nslookup www.isc.org

Server:         127.0.0.1
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   www.isc.org
Address: 204.152.184.88

real    0m0.008s
user    0m0.002s
sys     0m0.002s</div>
solo 8 millisecondi. Wow!
<h3>Installare bind9</h3>
Con Debian è semplicissimo:
<span class="&quot;codice&quot;">apt-get install bind9 bind9-host dnsutils</span>.
Usiamo bind9 che è la versione successiva al pacchetto bind (che sarebbe bind8)... A me mi piace piu' maggiormente!
Tutto qui!
<h3>Configurazione</h3>
Ci sono tre modi di funzionamento di un dnsserver ( "che funsia o che no?") nel caso in cui un indirizzo non sia presente nel database interno (nel caso in cui il DNS non sia autoritativo per quella zona):
<ol>
	<li>ROOT ONLY: Viene fatta richiesta ai root server il cui indirizzo è noto e da qui si scende fino a trovare l'IP corretto. I root server sono i DNS autoritativi per le zone come .it, .com, .net e così via</li>
	<li>FORWARD ONLY: La richiesta viene passata al DNS server del nostro provider (o quello che abbiamo impostato), se lui non ha risposta restituiamo un errore.</li>
	<li>FORWARD FIRST: Prima la richiesta viene passata al DNS del nostro provider, se questo non ha risposta vengono interrogati i root server.</li>
</ol>
Così com'è in Debian, bind9 è installato come "root only", noi lo imposteremo come "forward first" sia perchè in genere il DNS del nostro provider ci risponde piu' velocemente degli altri (anche avendo una buona cache), sia per generare meno traffico inutile in Internet.
<h4>Impostare il dns come forward first</h4>
Andiamo in /etc/bind (tutti i settaggi sono qui) e cambiamo il file named.conf.options così:
<div class="&quot;codice&quot;">options {
directory "/var/cache/bind";

<strong> forward first;
forwarders {
195.210.91.100;	#DNS server per Libero
193.70.192.100;
};
</strong>
auth-nxdomain no;    # conform to RFC1035
};</div>
In pratica ho solo aggiunto la dicitura "forward first;" e ho decommentato il blocco "forwarders" inserendogli i DNS di Libero (perchè mi collego con loro) se avete un altro provider cercate quali sono gli indirizzi dei suoi name server.
Ogni volta che fate qualche modifica, per renderle effettive dovete riavviare bind con <span class="&quot;codice&quot;">/etc/init.d/bind9 restart</span>.

Questo è già  sufficente per avere un server cacheonly. Il passaggio successivo renderà  il dominio autoritativo per la rete locale.
<h3>Impostare il DNS server come autoritativo per la rete locale</h3>
Questo passaggio renderà  un po' piu' sapiente il nostro server DNS che sarà  in grado di risolvere un po' di indirizzi nella rete locale senza dover ricorrere al file /etc/hosts di ogni computer.
Potrebbe essere utile per esempio per creare un dominio di secondo livello "pippo.localhost" che vada a prendere un sito diverso nel nostro server apache... quale che sia l'utilizzo, vediamo come impostarlo.
Facciamo un esempio: con un computer che si chiama sito.local (e questo è il suo nome completo o FQDN) c'è chi preferisce mantenere nomi completi composti da tre parti, come <strong>sito.local.net</strong>, fate come ritenete opportuno.
Voglio creare una entry che permetta di risolvere <strong>subsito.sito.local</strong> allo stesso indirizzo (nel mio caso c'è sempre un Apache che lo aspetta al varco).
Per farlo il nostro server DNS sarà  autoritativo per la rete local, vediamo come impostarlo:
<h4>Creiamo una nuova zona</h4>
Modifichiamo ancora il file /etc/bind/named.conf e aggiungiamo la zona "local" per la risoluzione degli IP:
<div class="&quot;codice&quot;">zone "local" in {
type master;
file "/etc/bind/db.localnet";
};</div>
"local" è il nome della rete della quale dettiamo legge (type master), le specifiche della zona le prenderemo dal file "/etc/bind/db.localnet" (in genere si tiene DB.NOMEDOMINO, ma in questo caso db.local c'era già  ;-) ).
<h4>Creare il file di zona</h4>
Creiamo ora il database per la risoluzione da nome a IP, in /etc/bind/db.localnet, e al suo interno scriviamo questi comandi (i commenti sono preceduti da "puntoevirgola" e non da "//"):
<div class="&quot;codice&quot;">$TTL 3h

\@. IN SOA sito.local. hostmaster.sito.local. (
2005030801;     Serial
3h;     Refresh
1h;     Retry
1w;     Expire
1h)     ;Negative cache

;dns server
IN NS sito.local.

;database risolutivo
sito.local.		IN	A	127.0.0.1
router.local.   IN	A	192.168.1.1

;alias
subsito.sito.local.      IN      CNAME   sito.local.
</div>

Cosa abbiamo fatto?
Innanzi tutto abbia impostato il "Time to live", la vita delle nostre richieste, per quanto tempo vengono considerate attendibili, 3 ore.
Nella riga 3, abbiamo detto che sito.local è l'autorità  del "dominio" local... La @ al posto di "local." dice a bind di prendere il nome della zona da named.conf. Facciamo attenzione che tutti i nomi finiscono con un punto "." per indicare che sono nomi completi, se specifichiamo sito.local (senza il punto finale) verrà  inteso sito.local.local (con anche il nome della zona). hostmaster.sito.local è l'indirizzo email dell'amministratore che va inteso come hostmaster@sito.local (la @ è appunto un carattere riservato in bind).
Piu' sotto, specifichiamo uno o piu' DNS server con la parola chiave "NS" (name server).
Ogni entry del database dei nomi viene specificata con la direttiva "A", mentre gli alias (pseudonimi) con la direttiva CNAME.
In questo caso abbiamo specificato subsito.sito.local come pseudonimo di sito.local, e abbiamo specificato l'IP di sito.local e di router.local.
<h3>This is the end my old friend</h3>
Controlliamo il file named.conf <span class="&quot;codice&quot;">named-checkconf</span> e il file di zona "db.localnet" con <span class="&quot;codice&quot;">named-checkzone local db.localnet</span>. 	Se non ci sono errori riavviamo dunque bind con <span class="&quot;codice&quot;">/etc/init.d/bind9 restart</span> e ci godiamo il nostro server DNS. Ciao!
