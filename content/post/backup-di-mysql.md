+++
author = "Tommaso Visconti"
categories = ["informatica", "software libero"]
date = 2007-09-28T07:03:37Z
description = ""
draft = false
slug = "backup-di-mysql"
tags = ["informatica", "software libero"]
title = "Backup di MySQL"

+++

In attesa di riuscire a capire qualcosa di <a href="http://www.bacula.org/">Bacula</a> ho trovato un ottimo script di backup per MySQL che si avvale solo dell'uso di <strong>mysqldump</strong>: <a href="http://members.lycos.co.uk/wipe_out/automysqlbackup/">automysqlbackup</a>.
Da <a href="http://sourceforge.net/projects/automysqlbackup/">sourceforge</a> si scarica direttamente lo script, che io ho spostato in<strong> /etc/cron.daily</strong>, ma che puo' essere anche lanciato manualmente.
All'inizio del file di script ci sono solo un paio di settaggi da fare, in particolare va impostato un utente mysql a cui vanno dati i permessi di SELECT, LOCK TABLES e SHOW VIEW


<blockquote>GRANT SELECT, LOCK TABLES, SHOW VIEW ON *.* TO 'user'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;</blockquote>

Una volta dati i permessi di esecuzione allo script e' possibile lanciarlo direttamente a mano per verificare che funzioni. Lo script creera' tre cartelle (daily, weekly e monthly) in cui mettera' i vari backup.

Intanto torno a studiarmi Bacula :)

