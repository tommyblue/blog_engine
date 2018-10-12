+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "raid", "mdadm", "memoria ausiliaria"]
date = 2009-09-09T05:53:20Z
description = ""
draft = false
slug = "attivare-un-array-raid-software-esistente-con-mdadm"
tags = ["informatica", "how-to", "raid", "mdadm", "memoria ausiliaria"]
title = "Attivare un array raid software esistente con mdadm"

+++

Può capitare, ad esempio se si avvia con una live un sistema con dischi in raid software con mdadm, che si debba attivare il raid esistente. Un tipico esempio può essere il dover recuperare dati da dischi estratti da un computer non più avviabile.

Se si avesse a disposizione il file di configurazione di mdadm <strong><em>/etc/mdadm.conf</em></strong>, attivare un array specifico consisterebbe in:
<pre># mdadm -As /dev/md0</pre>
Con l'opzione -s (--scan) la configurazione viene letta dal file.
Se invece (ed è la cosa più probabile nel caso descritto sopra) tale file non sia presente si può interrogare le partizioniÂ  dei dischi per capire come fosse fatto il raid di cui facevano parte:
<pre># mdadm -E /dev/sda2
/dev/sda2:
Magic : a92b4efc
Version : 00.90.00
 UUID : 8b8203c4:645c8ad6:1b1ad5b6:3e3bdf19
 Creation Time : Mon Jan  5 12:06:05 2009
 Raid Level : raid1
 Used Dev Size : 1951808 (1906.38 MiB 1998.65 MB)
 Array Size : 1951808 (1906.38 MiB 1998.65 MB)
 Raid Devices : 2
 Total Devices : 2
Preferred Minor : 1
 Update Time : Wed Sep  9 03:16:07 2009
 State : clean
 Active Devices : 2
Working Devices : 2
 Failed Devices : 0
 Spare Devices : 0
 Checksum : 8687470a - correct
 Events : 0.36
 Number   Major   Minor   RaidDevice State
this     0       8        2        0      active sync   /dev/sda2
 0     0       8        2        0      active sync   /dev/sda2
 1     1       8       18        1      active sync   /dev/sdb2</pre>
In questo caso /dev/sdc1 fa parte di un raid1 composto da <em><strong>/dev/sda2</strong></em> e <em><strong>/dev/sdb2</strong></em>.

A questo punto per attivarlo:
<pre># mdadm -A /dev/md0 /dev/sda2 /dev/sdb2</pre>
Ulteriori approfondimenti a <a href="http://linuxdevcenter.com/pub/a/linux/2002/12/05/RAID.html?page=last" target="_blank">questo indirizzo</a>.
