+++
author = "Tommaso Visconti"
categories = ["informatica", "debian", "vulnerability", "software libero", "openssl"]
date = 2008-05-16T13:39:48Z
description = ""
draft = false
slug = "chiudersi-fuori-casa"
tags = ["informatica", "debian", "vulnerability", "software libero", "openssl"]
title = "Chiudersi fuori casa"

+++

o quasi \"al volo\""

+++

<a href='/uploads/2008/04/lvm.png'><img src="/uploads/2008/04/lvm-300x259.png" alt="Schema LVM" title="Schema LVM" width="300" height="259" class="alignleft size-medium wp-image-140" /></a>Nel mio MacMini, oltre a MacOSX, erano installate due distribuzioni Linux: Gentoo 2007.0 e Fedora 8.

Dato che Gentoo non ne ha voluto sapere di far partire X ho iniziato ad usare in maniera assidua Fedora e ben presto è finito lo spazio sulla radice <em>/</em>, quindi ho deciso di cancellare il volume logico di Gentoo ed espandere quello di Fedora, insomma il vero pane di <strong>LVM</strong>.

Di seguito qualche appunto dato che, come avrete capito, questo blog è la mia <strong>memoria ausiliaria</strong> :)
<!--more-->
Tanto per cominciare, dato che uso LVM per la radice, non ho potuto utilizzare l'ottimo <strong>gestore di LVM</strong> presente in Fedora ed ho quindi riavviato usando il <strong>cd minimale di Gentoo che supporta LVM</strong>.
Prima però, col suddetto tool ho eliminato il volume <em>lvm0-gentoo</em>. Il tutto è molto user-friendly e non sto quindi a spiegare come si fa.

Appena avviato Gentoo bisogna caricare il modulo <em>dm-mod</em> con:
<code>~# modprobe dm-mod</code>

quindi attiviamo il gruppo di volumi logici che, nel mio caso, si trova in <em>/dev/lvm0</em>
<code>~# vgchange -a y /dev/lvm0</code>

e diamogli uno sguardo:
<code>~# vgdisplay /dev/lvm0</code>

<em>Attenzione in entrambi i precedenti comandi a non usare trailing slashes altrimenti non funziona.</em>
Notiamo lo spazio libero:
<code>Free PE  112/3.50GB</code>

Per espandere un volume possiamo usare entrambe le unità  di misura, io ho usato la prima:
<code>~# lvextend -l+112 /dev/lvm0/fedora</code>

altrimenti avrei potuto usare:
<code>~# lvextend -L+3.50G /dev/lvm0/fedora</code>

Per concludere bisogna estendere anche il filesystem, nel mio caso <em>ext3</em>. Prima però bisogna eseguirne un check:
<code>~# e2fsck -f /dev/lvm0/fedora
[..]
~# resize2fs /dev/lvm0/fedora
resize2fs 1.39 (29-May-2006)
Resizing the filesystem on /dev/lvm0/fedora to 1941504 (4k) blocks
The filesystem on /dev/lvm0/fedora is now 1941504 blocks long.</code>

Finito, riavviando la radice adesso ha le nuove dimensioni e per l'ennesima <strong>l'aver usato LVM mi ha risparmiato molte imprecazioni e, forse, formattazioni...</strong>

<strong>Link utili</strong>
<a href="http://tldp.org/HOWTO/LVM-HOWTO/">http://tldp.org/HOWTO/LVM-HOWTO/</a>
<a href="http://web.mit.edu/rhel-doc/3/rhel-sag-it-3/ch-lvm-intro.html">http://web.mit.edu/rhel-doc/3/rhel-sag-it-3/ch-lvm-intro.html</a>
<a href="http://it.wikipedia.org/wiki/Gestore_logico_dei_volumi">http://it.wikipedia.org/wiki/Gestore_logico_dei_volumi</a>

<strong>Edit:</strong>
Aggiungo che per estendere una partizione con filesystem XFS è sufficiente:
<code>~# xfs_growfs /home
</code>
nel caso della partizione home. Il tutto deve essere eseguito con la <strong>partizione montata</strong> :)
