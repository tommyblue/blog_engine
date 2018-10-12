+++
author = "Tommaso Visconti"
categories = ["how-to", "memoria ausiliaria", "linux", "mdadm", "raid", "informatica"]
date = 2010-09-28T12:16:31Z
description = ""
draft = false
slug = "sostituire-un-disco-in-un-raid-1-con-mdadm"
tags = ["how-to", "memoria ausiliaria", "linux", "mdadm", "raid", "informatica"]
title = "Sostituire un disco in un Raid 1 con mdadm"

+++

Lo devo fare da anni, finalmente prendo appunti per una cosa che mi capita di fare almeno un paio di volte l'anno e che, puntualmente, mi scordo come si fa :-)

Il punto è questo: sostituire un disco in un array Raid 1 quando si rompe. Riporto gli appunti presi qualche anno fa <a href="http://lilik.it/wiki/doku.php?id=raidsoftware" target="_blank">sulla wiki del LILiK</a>.

La situazione di un raid 1 con un disco rotto è più o meno questa:
<pre>~# cat /proc/mdstat

Personalities : [raid1]
md1 : active raid1 sda2[0] sdb2[1](F)
      1951808 blocks [2/1] [U_]

md2 : active raid1 sda3[0] sdb3[1](F)
      13671232 blocks [2/1] [U_]

md0 : active raid1 sda1[0] sdb1[1](F)
      96256 blocks [2/1] [U_]

unused devices: &lt;none&gt;</pre>
Si deve quindi rimuovere il disco dal raid:
<pre>mdadm /dev/md0 --fail /dev/hdb1 --remove /dev/hdb1
mdadm /dev/md1 --fail /dev/hdb2 --remove /dev/hdb2
mdadm /dev/md2 --fail /dev/hdb3 --remove /dev/hdb3</pre>
La situazione è quindi:
<pre>~# cat /proc/mdstat

Personalities : [raid1]
md1 : active raid1 sda2[0]
Â Â Â Â Â  1951808 blocks [2/1] [U_]

md2 : active raid1 sda3[0]
Â Â Â Â Â  13671232 blocks [2/1] [U_]

md0 : active raid1 sda1[0]
Â Â Â Â Â  96256 blocks [2/1] [U_]

unused devices: &lt;none&gt;</pre>
Si può quindi spengere la macchina e sostituire il disco.

Al riavvio bisogna creare sul nuovo disco lo stesso schema di partizioni presente su quello esistente. Questa procedura, molto semplice, può diventare rognosa se il nuovo disco è più piccolo (anche di poco) del vecchio. Consiglio quindi, quando si crea un sistema con partizioni in raid 1, di lasciare sempre un po' di spazio libero alla fine del disco per essere maggiormente sicuri di non moccolare poi in futuro :)

Ricreiamo le partizioni:
<pre>sfdisk -d /dev/sda | sfdisk /dev/sdb</pre>

<strong>ATTENZIONE:</strong> Se <strong>sfdisk</strong> si rifiutasse di scrivere le partizioni per problemi con i cilindri, provate ad usare l'opzione <em>--Linux</em> come descritto <a href="/2012/04/26/sostituire-un-disco-in-un-raid-software/">qui</a>. <em>(update 26/04/2012)</em>
<br /><br />
Se tutto è andato bene inseriamo le nuove partizioni nel raid:
<pre>mdadm /dev/md0 --add /dev/sdb1
mdadm /dev/md1 --add /dev/sdb2
mdadm /dev/md2 --add /dev/sdb3</pre>
L'ordine non conta, ma vi consiglio di farlo in ordine crescente di grandezza delle partizioni, cosicchè le partizioni più piccole si riallineino subito.
Adesso basta aspettare:
<pre>~# cat /proc/mdstat

Personalities : [raid1]
md1 : active raid1 sdb2[2] sda2[0]
Â Â Â Â Â  1951808 blocks [2/1] [U_]
Â Â Â Â Â  [=&gt;...................] recovery = 6.2% (123008/1951808) finish=2.4min speed=12300K/sec

md2 : active raid1 sdb3[2] sda3[0]
Â Â  Â Â  13671232 blocks [2/1] [U_]
Â Â Â Â Â  resync=DELAYED

md0 : active raid1 sdb1[1] sda1[0]
Â Â Â Â  96256 blocks [2/2] [UU]

unused devices: &lt;none&gt;</pre>
Per finire bisogna reinstallare il grub nell'MBR del nuovo disco. Nei nuovi s.o. dovrebbe bastare:
<pre>grub-install /dev/sdb</pre>
altrimenti:
<pre>grub&gt; root (hd1,0)
grub&gt; setup (hd1)</pre>
