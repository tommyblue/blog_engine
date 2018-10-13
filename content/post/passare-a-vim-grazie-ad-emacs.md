+++
author = "Tommaso Visconti"
categories = ["informatica", "editor", "how-to", "vim"]
date = 2012-09-01T17:38:51Z
description = ""
draft = false
slug = "passare-a-vim-grazie-ad-emacs"
tags = ["informatica", "editor", "how-to", "vim"]
title = "Passare a Vim grazie ad Emacs"

+++



**Grazie [Sciamp](http://scia.mp) per avermi convinto a passare a Vim parlandomi di Emacs :)**

Lo so, sembra uno scherzo, eppure è proprio vero! Era da tanto che volevo cambiare editor passando da Textmate a qualcos'altro, ho intravisto Sublime Text 2, ma volevo qualcosa di open source. Da un po' di tempo [Alessandro](https://github.com/sciamp) stava rompendo le scatole a tutti su quanto è figo Emacs :) e avevo iniziato a lavorarci un po', ma non sono mai riuscito ad entrarci in sintonia. Arriviamo ai giorni nostri e in particolare al primo incontro ufficiale del [Ruby Social Club Firenze](http://firenze.ruby-it.org/2012/05/02/2-maggio-al-pangoro) dove ho assistito al talk proprio di Alessandro ["Ma perchè non Emacs? - a caccia di feature che sicuramente esistono già ](http://vimeo.com/41595912). Il talk è stato illuminante, talmente interessante che mi sono detto: "Ma se Emacs fa tutte queste cose (e io mi trovo molto bene con Vim), possibile che anche Vim non le faccia?". Mi sono guardato un po' di video (scoprendo che, ovviamente, le faceva) e alla fine ho deciso di abbandonare Textmate e passare a Vim!

Lo ammetto: non è stato subito semplice: stupito dai video e dagli articoli letti quà  e là  ho installato plugin, clonato repository, fatto configurazioni per lo più senza sapere troppo cosa stavo facendo e mi sono trovato in situazioni veramente strane, tipo non capire perchè il Tab non tabbava oppure vedere apparire cose a caso in conseguenza di shortcut che non sapevo di aver digitato! L'editor risultava comunque molto potente, ma non sentivo di padroneggiarlo abbastanza anche se non ho mai rimpianto troppo TextMate. Poi ho letto [questo articolo di Yahuda Katz](http://yehudakatz.com/2010/07/29/everyone-who-tried-to-convince-me-to-use-vim-was-wrong/) e ho trovato le sue osservazioni molto giuste: quando si passa a editor potenti come Emacs o Vim bisogna evitare il **troppo**, ovvero le centinaia di funzioni e plugin che gli esperti di quell'editor ti suggeriscono di installare subito come se fossero essenziali, quando invece ti trovi a non capirci più un tubo.

Ho quindi deciso di eliminare **~/.vim/** e **~/.vimrc** e ricominciare da capo un passo alla volta. Userò questo articolo per tenere traccia delle cose che ho fatto.
Non so bene cosa verrà  fuori, intanto sappiate che uso sia Vim (sui server e da terminale) che GVim (su Fedora) e Mvim (sul Mac), quindi mi aspetto che le configurazioni debbano funzionare su tutte e tre le varianti dell'editor.
Troverete la versione aggiornata e completa dei file nel [mio repository GitHub dedicato a Vim](https://github.com/tommyblue/vim) (leggete il README prima di usarlo).

**N.B.**: d'ora in poi scriverò sempre le configurazioni riferendomi al file *~/.vimrc* ma se state usando il mio repository quel file è praticamente vuoto e include il file *~/.vim/vimrc*, dove effettivamente troverete le configurazioni. A parte il cambio di file, la sostanza non cambia :)

## Configurazioni di base

Tutto ciò che concerne Vim è essenzialmente in due posti: il file *~/.vimrc* e la cartella *~/.vim/*. Il file *~/.vimrc* viene eseguito al lancio del programma mentre nella cartella si trovano tutte le estensioni (colori, plugin, ecc.).
Come prima cosa impostiamo un po' di configurazioni di base in *~/.vimrc*:


```vim

set showcmd     "show incomplete cmds down the bottom
set showmode    "show current mode down the bottom

set incsearch   "find the next match as we type the search
set hlsearch    "hilight searches by default

"turn off needless toolbar on gvim/mvim
set guioptions-=T

"indent settings
set tabstop=4
set shiftwidth=4
set softtabstop=4
set cindent
set smartindent
set autoindent
set expandtab

"folding settings
set foldmethod=indent   "fold based on indent
set foldnestmax=3       "deepest fold is 3 levels
set nofoldenable        "dont fold by default

set wildmode=list:longest   "make cmdline tab completion similar to bash
set wildmenu                "enable ctrl-n and ctrl-p to scroll thru matches

" Vim tabs navigation
nmap <leader>] :tabn<CR>
nmap <leader>[ :tabp<CR>


```


Per Vim sono disponibili tantissimi [schemi di colore](http://www.vim.org/scripts/script_search_results.php?keywords=&script_type=color+scheme&order_by=rating&direction=descending&search=search), per installarli è necessario copiare il file *.vim* contenente lo schema in *~/.vim/colors*. A quel punto è possibile abilitare a runtime lo schema colori con:

	:colorscheme MyScheme

oppure, usando *~/.vimrc*:

	colorscheme MyScheme

Di seguito una configurazione leggermente più complessa riguardante lo schema colori che tiene conto dell'interfaccia di Vim usata:

```vim

" Color scheme
if has("gui_running")
    "tell the term has 256 colors
    set t_Co=256

    colorscheme railscasts
    set guitablabel=%M%t
    set lines=40
    set columns=115

    if has("gui_gnome")
	set term=gnome-256color
	colorscheme railscasts
	set guifont=Monospace\ Bold\ 12
    endif

    if has("gui_mac") || has("gui_macvim")
	set guifont=Menlo:h14
	" key binding for Command-T to behave properly
	" uncomment to replace the Mac Command-T key to Command-T plugin
	"macmenu &File.New\ Tab key=<nop>
	"map <D-t> :CommandT<CR>
	" make Mac's Option key behave as the Meta key
    endif

    if has("gui_win32") || has("gui_win32s")
	set guifont=Consolas:h12
	set enc=utf-8
    endif
else
    "dont load csapprox if there is no gui support - silences an annoying warning
    let g:CSApprox_loaded = 1

    "set railscasts colorscheme when running vim in gnome terminal
    if $COLORTERM == 'gnome-terminal'
	set term=gnome-256color
	colorscheme railscasts
    else
	if $TERM == 'xterm'
	    set term=xterm-256color
	    colorscheme railscasts
	else
	    colorscheme default
	endif
    endif
endif

```


Personalmente non modifico il tasto Leader (di default *\\*), ma se lo volete fare:

```vim

let mapleader=","

```


## Pathogen

Installare un plugin in Vim vuol dire copiare i suoi file nella cartella *~/.vim/* e in particolare nelle sue varie sottodirectory (*plugin*, *doc*, *autoload*, ecc). Non mi piace molto dover dividere i file di uno stesso plugin ed evidentemente non sono il solo dato che esiste il plugin [Pathogen](http://www.vim.org/scripts/script.php?script_id=2332) che permette di scompattare ogni plugin nella sua cartella in *~/.vim/bundle/*.
Per installare il plugin bisogna copiare il plugin in *~/.vim/autoload* e creare la cartella *~/.vim/bundle/*:

```bash

mkdir -p ~/.vim/autoload ~/.vim/bundle
curl 'www.vim.org/scripts/download_script.php?src_id=16224' > ~/.vim/autoload/pathogen.vim

```


Per attivare il plugin basta inserire in *~/.vimrc*:

```vim

"necessary on some Linux distros for pathogen to properly load bundles
filetype on
filetype off

"load pathogen managed plugins
call pathogen#infect()

```


## NERDTree

Adesso che abbiamo installato Pathogen cosa di meglio se non provarlo! Uno dei plugin che uso di più è sicuramente [NerdTree](http://www.vim.org/scripts/script.php?script_id=1658), che permette la visualizzazione dell'albero delle directory e dei file. Per installarlo quindi si seguono le [istruzioni del repository GitHub](https://github.com/scrooloose/nerdtree), ovvero:

```bash

cd ~/.vim/bundle
git clone https://github.com/scrooloose/nerdtree.git

```


Personalmente utilizzo queste configurazioni in *~/.vimrc* per NerdTree:

```vim

" Visualizzo NERDTree con i tasti 'wm'
nmap wm :NERDTree<cr>
" Ignoro i file di backup di Vim
let NERDTreeIgnore=['\.swp$']
" Utilizzo <leader>p per mostrare e nascondere NERDTree
silent! nmap <silent> <Leader>p :NERDTreeToggle<CR>

```


## Vundle

Come abbiamo appena visto installare i plugin è molto semplice, specialmente con Pathogen, ma a lungo andare si potrebbe perdere un po' traccia di cosa si è installato e, soprattutto, se i plugin installati sono anche aggiornati. Per ovviare al problema uso [Vundle](https://github.com/gmarik/vundle), un plugin che, sfruttando Pathogen, permette di automatizzare le operazioni di installazione e aggiornamento dei plugin. Per installarlo:

```bash

git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

```


La configurazione a questo punto è piuttosto semplice:

```vim

set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required!
Bundle 'gmarik/vundle'

" Set plugins here...


filetype plugin indent on     " required!

```


Se a questo punto si vuole installare un plugin da GitHub (ad esempio reinstalliamo, dopo averlo eliminato, NerdTree), basta inserire in *~/.vimrc*:

```vim

Bundle 'scrooloose/nerdtree.git'

```


Se il plugin non fosse su GitHub è sufficiente indicare l'url GIT completo.

Una volta inserito il plugin si lancia Vim e si esegue:

	:BundleInstall

Se si vogliono vedere i bundle presenti:

	:BundleList

se si vogliono aggiornare i bundle installati:

	:BundleInstall!

e infine se si vuole eliminare un plugin si elimina la riga corrispondente in *~/.vimrc* e si esegue:

    :BundleClean

Niente di più semplice.

Adesso che Vim è configurato per installare velocemente i plugin inizio con una carrellata di plugin che ho installato. Vi consiglio anche la visione di questa interessante serie di video intitolata [VIM Essential Plugins](http://net.tutsplus.com/sessions/vim-essential-plugins/).

## Fugitive

Inizio con Fugitive, un plugin che trasforma Vim in un client Git. Personalmente, almeno per ora, non uso direttamente le funzionalità  per Git, ma mi è utile per visualizzare lo stato del repository su cui sto lavorando. Dopo aver inserito il bundle:

```vim

Bundle 'tpope/vim-fugitive'

```


per vedere lo stato del repository si inserisce in *~/.vimrc*:

```vim

set statusline+=%{fugitive#statusline()}

```


Per una panoramica più completa del plugin esiste una [serie di screencast su Fugitive](http://vimcasts.org/blog/2011/05/the-fugitive-series/)

## SnipMate

[Snipmate](https://github.com/msanders/snipmate.vim) è un plugin che permette l'uso degli snippet, ovvero l'uso di una stringa che, seguita dal Tab, genera del codice. Snipmate non va d'accordo con Pathogen quindi non è possibile utilizzare Vundle. Per installarlo bisogna quindi seguire la guida:

```bash

git clone git://github.com/msanders/snipmate.vim.git
cd snipmate.vim
cp -R * ~/.vim

```


Per fare un esempio, si può aprire un file html, digitare *html* seguito da un Tab e Snipmate genererà :

```html

<html></html>

```


Se lavorate molto con l'HTML vi consiglio di dare un bello sguardo a [Sparkup](https://github.com/rstacruz/sparkup) che permette di creare HTML molto complesso con poco, ad esempio:

    nav > ul > li > a*4 { Links }

seguito da un Tab produce:

```html

<nav>
   <ul>
      <li>
         <a href=""> Links </a>
         <a href=""> Links </a>
         <a href=""> Links </a>
         <a href=""> Links </a>
      </li>
   </ul>
</nav>

```


Mica male... :)

## Command-T

[Command-T](https://github.com/wincent/Command-T) prende direttamente spunto dal Command-T di TextMate e serve per trovare velocemente un file e aprirlo: basta digitare *leader-t* e iniziare a digitare il nome di un file per trovarlo.

La sua installazione è molto più complessa dei plugin installati finora, quindi mi ci soffermerò un po' di più.

Intanto i requisiti: Command-T richiede che sia installato Ruby (e che sia della stessa versione usata per compilare Vim) e alcune librerie di sistema. Su Fedora i pacchetti necessari sono:

    yum install ruby ruby-devel libxml2-devel libxslt-devel

Il plugin si può installare con Vundle, quindi in *~/.vimrc*:

```vim

Bundle 'git://git.wincent.com/command-t.git'

```


e, come al solito, si installa con:
```vim

:BundleInstall

```


Fatto questo il plugin va compilato. Se, come me, usate RVM, prima di compilare Command-T, switchate al ruby di sistema con:

    rvm use system

entrate poi nella cartella *~/.vim/bundle/command-t/ruby/command-t/* e lanciate:

```bash

ruby extconf.rb
make

```


Se tra l'installazione del plugin e la sua compilazione provate a lanciare vim vi troverete con un bel **Segmentation Fault** :)

Esiste anche un plugin alternativo che promette faville, specialmente per chi ha MacOSX, [PeepOpen](https://peepcode.com/products/peepopen), ma costa 12$

## Vim-Rails

Eccoci al mio plugin preferito: [Vim-Rails](https://github.com/tpope/vim-rails). Chiunque programmi in Ruby on Rails amerà  *:Rmodel*, *:Rview*, *:Rcontroller* per navigare velocemente l'MVC di una risorsa, *:Rextract* per creare un partial al volo di un codice selezionato, ecc.
Per installarlo, in *~/.vimrc*:

```vim

Bundle 'tpope/vim-rails.git'

```


## Altri plugin

Termino con una breve descrizione di altri plugin utili:

* [SuperTab](https://github.com/ervandew/supertab) permette l'autocompletamento con un utile menù a tendina da cui scegliere l'opzione desiderata
* [DelimitMate](https://github.com/Raimondi/delimitMate.git): chiusura automatica delle parentesi
* [CloseTag](https://github.com/docunext/closetag.vim.git): premendo *Ctrl-_* in un file HTML chiude in automatico un Tag rimasto aperto
* [TagBar](http://majutsushi.github.com/tagbar/): un plugin simile a [TagList](http://vim.sourceforge.net/scripts/script.php?script_id=273) che genera la lista di classi/metodi/ecc. del file aperto (richiede exuberant-ctags)
* [ZenCoding](https://github.com/mattn/zencoding-vim/): abbreviazioni per file HTML in stile [zen-coding](http://code.google.com/p/zen-coding/)
* [CSS Syntax](https://github.com/vim-scripts/Better-CSS-Syntax-for-Vim): una versione migliorata della colorazione dei CSS

Questa volta, più che mai, un augurio di *Happy Hacking!*
