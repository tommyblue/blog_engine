+++
author = "Tommaso Visconti"
categories = ["informatica", "fedora", "memoria ausiliaria", "how-to", "mac osx", "layout", "tastiera"]
date = 2010-11-24T17:12:56Z
description = ""
draft = false
slug = "configurare-su-linux-la-tastiera-come-su-macosx"
tags = ["informatica", "fedora", "memoria ausiliaria", "how-to", "mac osx", "layout", "tastiera"]
title = "Configurare su Linux la tastiera come su MacOSX"

+++

Saltando spesso da Mac a Fedora ho sempre odiato veder cambiare il comportamento della tastiera. Riassumo quindi i pochi passaggi necessari a riprodurre su Linux (quasi) lo stesso comportamento della tastiera in Mac.

Innanzitutto il layout. La mia tastiera è "Internazionale Inglese", ovvero, oltre alla disposizione USA, ha il tasto <strong>`~</strong> a sinistra della<strong> z</strong> e il tasto <strong>Â§Â±</strong> a sinistra dell'<strong>1</strong>.
Per ottenere questo layout ho impostato (in Gnome da <em>Sistema &gt; Preferenze &gt; Tastiera</em>) la tastiera USA e creato nella mia home il file <strong>.xmodmaprc</strong> con questo contenuto:
<pre>keycode 94 = grave asciitilde grave asciitilde dead_grave dead_horn
keycode 49 = section plusminus section plusminus section plusminus</pre>
Sempre dal menù di configurazione della tastiera , pannello Disposizioni, tasto Opzioni, ho selezionato:
<ul>
	<li>Comportamento tasto Alt/Win =&gt; Control è applicato ai tasti Win</li>
	<li>Opzioni varie di compatibilità  =&gt; Apple Keyboard alluminio</li>
	<li>Posizione tasto Compose =&gt; Alt destro</li>
</ul>
Quest'ultima cosa è l'unica che veramente mi scoccia dato che su Mac viene usato l'alt sinistro, ma con Linux non sembra essere possibile.

Per terminare ho implementato un piccolo script che modifica la luminosità  della tastiera. àˆ composto da 3 file (devono tutti essere eseguibili):

<strong>modify_backlight</strong>
<pre>#!/bin/bash
echo $1 &gt; /sys/devices/platform/applesmc.768/leds/smc\:\:kbd_backlight/brightness</pre>
<strong>brightness_up</strong>
<div id="_mcePaste">
<pre>#!/bin/bash
declare -i VAL
declare -i NEW_VAL
declare -i NEW_VAL_PERC
VAL=`cat /sys/devices/platform/applesmc.768/leds/smc\:\:kbd_backlight/brightness`
NEW_VAL=$VAL+50
if [ $VAL -ge 250 ]; then
<span style="white-space: pre;">	</span>NEW_VAL=255
fi
NEW_VAL_PERC=NEW_VAL*100/255
notify-send -u low -t 500 -i /usr/share/icons/gnome-colors-common/scalable/notifications/notification-keyboard-brightness-high.svg "Keyboard brightness" "Increasing keyboard backlight brightness to $NEW_VAL_PERC%"
/usr/bin/sudo /home/tommyblue/bin/modify_backlight $NEW_VAL</pre>
</div>
<strong>brightness_down</strong>
<pre>#!/bin/bash
declare -i VAL
declare -i NEW_VAL
declare -i NEW_VAL_PERC
VAL=`cat /sys/devices/platform/applesmc.768/leds/smc\:\:kbd_backlight/brightness`
NEW_VAL=$VAL-50
if [ $VAL -le 8 ]; then
<span style="white-space: pre;">	</span>NEW_VAL=0
fi
NEW_VAL_PERC=NEW_VAL*100/255
notify-send -u low -t 500 -i /usr/share/icons/gnome-colors-common/scalable/notifications/notification-keyboard-brightness-low.svg "Keyboard brightness" "Decreasing keyboard backlight brightness to $NEW_VAL_PERC%"
/usr/bin/sudo /home/tommyblue/bin/modify_backlight $NEW_VAL</pre>
Quindi per modificare la luminosità  con i tasti F5 e F6 basta aprire <em>Sistema &gt; Preferenze &gt; Scorciatoie da tastiera</em> e aggiungere due scorciatoie personalizzate che vadano a richiamare i due script <strong>brightness_up</strong> e <strong>brightness_down</strong>. Dato che gli script vanno a modificare dei file di root, bisogna anche inserire in /etc/sudoers la seguente riga:
<pre>tommyblue ALL=NOPASSWD:/home/tommyblue/bin/modify_backlight</pre>
Ovviamente utente e path devono essere opportunamente modificate.
