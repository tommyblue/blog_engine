+++
author = "Tommaso Visconti"
categories = ["informatica", "fedora", "lvm", "xfs", "software libero"]
date = 2009-03-19T09:05:06Z
description = ""
draft = false
slug = "convertire-il-filesystem-della-partizione-root"
tags = ["informatica", "fedora", "lvm", "xfs", "software libero"]
title = "Convertire il filesystem della partizione root"

+++

<strong>Ovvero come installare Fedora 10 da cd utilizzando XFS come filesystem per la root (/) :)</strong>

<em>Nota: avrete bisogno di due partizioni di almeno 4/5 GB</em>

L'uso di XFS è molto utile specialmente se utilizzato in coppia con LVM (in particolare per espandere le partizioni "al volo"), cosa che spiegherò di seguito.
I passi sono molto semplici:
<ol>
	<li>Avviate dal cd di Fedora 10</li>
	<li>Installate normalmente Fedora utilizzando una partizione LVM di almenoÂ  5.0 GB il cui filesystem sarà  scelto tra quelli disponibili nell'installer (ext2 o ext3). <strong>La partizione /boot non può stare su LVM, quindi dedicategli una piccola partizione primaria (200 Mb generalmente bastano).</strong></li>
	<li>Una volta terminato create una nuova partizione LVM e formattatela in XFS:
<ul>
	<li>aprite un terminale e digitate <strong><em>su</em></strong> diventando <em>root</em></li>
	<li>installate il necessario per maneggiare i filesystem XFS: <em><strong>yum install xfsprogs</strong></em></li>
	<li>Create un nuovo volume logico: <strong><em>lvcreate -L 5G -n fedora VolGroup00</em></strong></li>
	<li>Formattate in XFS il fs appena creato: <strong><em>mkfs.xfs /dev/VolGroup00/fedora</em></strong></li>
</ul>
</li>
	<li>Adesso montate le due partizioni e copiate i dati da una all'altra:
<ul>
	<li><em><strong>mkdir /mnt/old_root &amp;&amp; mkdir /mnt/fedora</strong></em></li>
	<li><em><strong>mount /dev/VolGroup00/old_root /mnt/old_root &amp;&amp; mount /dev/VolGroup00/fedora /mnt/fedora</strong></em></li>
	<li><em><strong>cp -a /mnt/old_root/* /mnt/fedora</strong></em></li>
</ul>
</li>
	<li>Terminata quest'operazione bisogna editare <em>grub</em> (il file <em><strong>/mnt/boot/grub/menu.lst</strong></em>, dovrete prima montare la partizione ad es. in <strong>/mnt/boot</strong>) modificando il filesystem root: la voce dovrebbe essere qualcosa tipo <strong>root=UUID=0f01a383-6557-4d17-be11-14bd50c6c4f7</strong>. Modificatela in <strong>root=/dev/VolGroup00/fedora</strong></li>
	<li>Editate anche il file /mnt/fedora/etc/fstab editando la linea:
<strong>/dev/lvm0/old_root / ext3 defaults 1 1</strong>
in
<strong>/dev/lvm0/fedora / xfs defaults 1 1</strong></li>
	<li>Per finire bisogna ricreare il file initrd quindi, supponendo che il kernel installato sia <em>2.6.27.5-117.fc10.i686.img </em>e che la nuova partizione XFS sia ancora montata in <strong><em>/mnt/fedora</em></strong>:
<ul>
	<li><em><strong>mount -t proc none /mnt/fedora/proc</strong></em></li>
	<li><em><strong>mount -o bind /dev /mnt/fedora/dev</strong></em></li>
	<li><em><strong>chroot /mnt/fedora /bin/bash</strong></em></li>
	<li><em><strong>mount /boot</strong></em></li>
	<li><em><strong>mv /boot/initrd-2.6.27.5-117.fc10.i686.img /boot/initrd-2.6.27.5-117.fc10.i686.img.backup</strong></em></li>
	<li><em><strong>mkinitrd /boot/initrd-2.6.27.5-117.fc10.i686.img 2.6.27.5-117.fc10.i686</strong></em></li>
</ul>
</li>
	<li>Bene, se avete fatto tutti i passaggi correttamente (e io non mi sono scordato nulla) potete riavviare e avrete il filesystem di root in XFS!</li>
</ol>
Adesso che avete LVM e XFS se lo spazio nella partizione si sta esaurendo lo potete aumentare al volo senza neanche riavviare. I passi sono questi:
<ol>
	<li>Ingrandite di 10GB la partizione: <strong><em>lvextend -L+10G /dev/VolGroup00/fedora</em></strong></li>
	<li>Adattate il filesystem alla nuova dimensione: <em><strong>xfs_growfs /</strong></em></li>
	<li>Finito! La partizione di root adesso ha 10GB liberi in più :D</li>
</ol>
