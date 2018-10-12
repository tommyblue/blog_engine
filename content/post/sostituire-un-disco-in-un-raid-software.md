+++
author = "Tommaso Visconti"
categories = ["informatica", "mdadm", "raid", "how-to"]
date = 2012-04-26T11:47:30Z
description = ""
draft = false
slug = "sostituire-un-disco-in-un-raid-software"
tags = ["informatica", "mdadm", "raid", "how-to"]
title = "Sostituire un disco in un raid software"

+++



Ho recentemente scoperto un'interessante opzione di _sfdisk_ che risolve molti problemi quando si deve sostituire un disco di un raid software. Integro quindi [l'articolo originale](/2010/09/28/sostituire-un-disco-in-un-raid-1-con-mdadm/) segnlando questa opzione, da usare nel caso in cui al comando:

	sfdisk -d /dev/sda | sfdisk /dev/sdb

sfdisk si rifiuti di partizionare correttamente _/dev/sdb_ a causa di problemi con i cilindri.
Dato che Linux è molto meno schizzinoso del DOS, esiste un'opzione per ignorare problemi che con Linux, appunto, non sono tali:

	sfdisk -d /dev/sda | sfdisk --Linux /dev/sdb

et voilà ! :)
