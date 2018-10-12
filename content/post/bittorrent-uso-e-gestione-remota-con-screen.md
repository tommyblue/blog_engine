+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "torrent"]
date = 2006-05-07T05:45:44Z
description = ""
draft = false
slug = "bittorrent-uso-e-gestione-remota-con-screen"
tags = ["informatica", "how-to", "torrent"]
title = "Bittorrent - uso e gestione remota con screen"

+++

Il pacchetto da installare è <strong>bittorent</strong>
Una volta installato si entra nella cartella creata per il download dei torrent e si lancia <strong>screen</strong> che emulerà  un terminale.
In questo terminale emulato si lancerà 
<pre>macondo:~$ btlaunchmanycurses .</pre>
Viene usata dal programma una chiara interfaccia ncurses che mostra i download/upload attivi.
Con questo programma tutti i file .torrent aggiunti alla cartella di download vengono automaticamente aggiunti ai download in corso.
Se adesso volete scollegare screen dalla console è sufficiente usare <strong>Ctrl-a + Ctrl-d</strong>. A questo punto (se siete collegati in ssh) potete chiudere tranquillamente la connessione.
Per riprendere il controllo della sessione di screen usate il comando
<pre>macondo:~$ screen -r</pre>