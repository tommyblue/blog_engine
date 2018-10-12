+++
author = "Tommaso Visconti"
categories = ["informatica", "memoria ausiliaria", "ssh", "how-to"]
date = 2011-11-10T10:09:40Z
description = ""
draft = false
slug = "accesso-ssh-inverso"
tags = ["informatica", "memoria ausiliaria", "ssh", "how-to"]
title = "Accesso SSH inverso"

+++

Può tornare utile accedere via SSH ad un pc/server non pubblico. Capita ad esempio quando un cliente disperato sta provando a mettere le mani sul server impallato e tu stai cercando di dettargli i comandi al telefono (generalmente con pessimi risultati).

Quindi basta avere un server SSH a cui il cliente possa arrivare con un utente da utilizzare.
Supponendo che il server da raggiungere sia <em>ssh-server.test.com</em> e l'utente <em>test</em>, basta che digiti il comando:
<pre>ssh -R 9000:127.0.0.1:22 -p 22 -l test ssh-server.test.com -N</pre>
Una volta inserita la password la sua console rimarrà  "appesa" e voi, dal vostro server, potrete accedere alla sua macchina con:
<pre>ssh utente@127.0.0.1 -p 9000</pre>
Chiaramente avrete bisogno di un utente sulla sua macchina.

Et voilà , cliente contento e nessuna crisi di nervi per voi nel tentare di spiegargli dove mettere spazi e slash :)
