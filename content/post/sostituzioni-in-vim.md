+++
author = "Tommaso Visconti"
categories = ["informatica", "memoria ausiliaria", "how-to", "vi", "linux&amp;c."]
date = 2009-09-10T05:41:42Z
description = ""
draft = false
slug = "sostituzioni-in-vim"
tags = ["informatica", "memoria ausiliaria", "how-to", "vi", "linux&amp;c."]
title = "Sostituzioni in Vim"

+++

Per <strong>sostituire</strong> un parola con un'altra in <strong>Vim</strong> il comando è il seguente:
<pre>:rs/foo/bar/a</pre>
dove <em><strong>r</strong></em> è il range, <em><strong>foo</strong></em> è la parola da sostituire con <em><strong>bar</strong></em> e <em><strong>a</strong></em> sono gli argomenti.

Ad esempio per sostituire in tutto il file tutte le occorrenze di <em><strong>foo</strong></em> con <em><strong>bar</strong></em> il comando è:
<pre>:%s/foo/bar/g</pre>
Uteriori informazioni a <a href="http://www.tuxfiles.org/linuxhelp/vimcheat.html" target="_blank">questo indirizzo</a>.
