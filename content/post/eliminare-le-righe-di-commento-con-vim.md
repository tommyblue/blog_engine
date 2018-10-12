+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "memoria ausiliaria", "vim", "regexp"]
date = 2010-01-21T09:23:29Z
description = ""
draft = false
slug = "eliminare-le-righe-di-commento-con-vim"
tags = ["informatica", "how-to", "memoria ausiliaria", "vim", "regexp"]
title = "Eliminare le righe di commento con Vim"

+++

Muovendo i miei primi passi nelle <em>regular expressions</em> ho cercato la regexp per eliminare le righe di commento da un file, ovviamente con <em>Vim</em>. Il risultato è questo:
<pre>:g/^\s*#.*/d</pre>
mi resta da capire perché questa seconda regexp non funziona:
<pre>:g/^[# ]+.*/d</pre>
<img class="size-full wp-image-790 aligncenter" title="Regexp" src="/uploads/2010/01/regexp.jpg" alt="" width="180" height="240" />
