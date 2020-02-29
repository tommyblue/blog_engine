+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "software libero", "icinga", "nagios", "monitoring"]
date = 2012-06-13T11:30:15Z
description = ""
draft = false
slug = "monitoraggio-distribuito-con-nagiosicinga-e-nsca"
tags = ["informatica", "how-to", "software libero", "icinga", "nagios", "monitoring"]
title = "Monitoraggio distribuito con Nagios/Icinga e NSCA"

+++



Sebbene Icinga/Nagios e NRPE siano un'ottima coppia per monitorare le macchine (sia via socket che internamente), a volte possono non bastare.
Potrebbe infatti essere utile distribuire i check su più macchine, sia per un fattore di carico sia per aggirare eventuali firewall.

Partendo quindi da una macchina con un server Icinga o Nagios funzionante, come descritto <a href="http://tommyblue.it/2011/03/08/realizzare-un-sistema-di-monitoraggio-con-icinga">qui</a>, mostrerò come configurare un secondo server remoto che comunica via NSCA il risultato dei check al server principale.

# Configurazione del server distribuito (client)

Sulla macchina client (Ubuntu server 12.04 LTS) si installano i seguenti pacchetti:

```bash
sudo apt-get install icinga-core nsca nagios-plugins-extra
```

Bisogna configurare */etc/send_nsca.cfg* inserendo la password e la scelta di cifratura. Entrambi i dati andranno fedelmente riprodotti nel server NSCA.

Adesso si edita il file */etc/icinga/commands.cfg* aggiungendo il comando che invierà  i dati al server NSCA:
```txt
define command{
    command_name    submit_check_result
    command_line    /usr/share/icinga/plugins/eventhandlers/distributed-monitoring/submit_check_result_via_nsca $HOSTNAME$ '$SERVICEDESC$' $SERVICESTATEID$ '$SERVICEOUTPUT$'
}
```
Nel file */usr/share/icinga/plugins/eventhandlers/distributed-monitoring/submit_check_result_via_nsca* bisogna editare la variabile *IcingaHost* con l'hostname del server Icinga principale.

Il concetto di funzionamento del monitoraggio distribuito è che i server secondari inviano al master i risultati dei check. Per farlo bisogna attivare il servizio OCSP (**obsessive compulsive service processor**) in */etc/icinga/icinga.cfg* dicendogli di usare il comando precedentemente definito per comunicare al server NSCA i risultati dei check:
```txt
obsess_over_services=1
ocsp_command=submit_check_result
ocsp_timeout=5
```
Dato che il server slave deve soltanto comunicare i risultati dei check, si disabilitano le notifiche dei servizi in *objects/generic-service_icinga.cfg* impostando:
```txt
notifications_enabled   0
```
In questo modo eventuali allarmi partiranno soltanto dal server principale.

Per finire si può definire un check base:
```txt
define host{
        use                     generic-host
        host_name               base-icinga
        alias                   Icinga server
        address                 127.0.0.1
}

define service{
        use                             generic-service
        host_name                       base-icinga
        service_description             Disk Space
        check_command                   check_all_disks!20%!10%
}
```
# Integrazione di NSCA nel server principale e ricezione dei check passivi

Passiamo al server principale e per prima cosa definiamo un servizio passivo:
```txt
define service{
    use                     generic-service   ; template to inherit from
    name                    passive-service   ; name of this template
    active_checks_enabled   0                 ; no active checks
    passive_checks_enabled  1                 ; allow passive checks
    check_command           check_dummy!0     ; use "check_dummy", RC=0 (OK)
    check_period            24x7              ; check active all the time
    check_freshness         0                 ; don't check if check result is "stale"
    register                0                 ; this is a template, not a real service
    }
```
Tale template verrà  usato per ogni servizio passivo.

Per abilitare la ricezione di check passivi in *icinga.cfg* devono essere presenti:
```txt
check_external_commands=1
command_check_interval=<n>[s]
log_passive_checks=1
```
Si faccia attenzione: i check passivi non arriveranno dal server slave, ma dal server NSCA che sarà  installato su questa stessa macchina e che li passa a Icinga.
Si installa quindi il pacchetto **nsca** e si configura */etc/nsca.cfg*, ricordandosi di settare la password e la cifratura inseriti nel client. Si dia un occhio anche ad altre configurazioni, ad esempio il percorso al file che accetta i check passivi, nel mio caso:
```txt
command_file=/usr/local/icinga/var/rw/icinga.cmd
```
Una volta avviato il server NSCA (standalone o via xinetd) se dal client si lancia una connessione questo dovrebbe essere il risultato:
```txt
echo -e "A\tB\tC\tD\n" | /usr/share/icinga/plugins/eventhandlers/distributed-monitoring/submit_check_result_via_nsca
0 data packet(s) sent to host successfully.
```
Adesso si può definire l'host e il check passivo:
```txt
define host {
        use             drwolf-server
        host_name       base-icinga
        alias           Icinga@base
        address         127.0.0.1
}

define service{
    use                     passive-service
    host_name               base-icinga
    service_description     Current Users
    }
```
Al termine si può riavviare Icinga e tutto dovrebbe essere a posto.
Attenzione che il nome dell'host (**host_name**) e il nome del servizio (**service_description**) siano esattamente gli stessi definiti nello slave, altrimenti nel file */var/log/icinga/icinga.log* troverete messaggi come questo:
```txt
[1339598868] EXTERNAL COMMAND: PROCESS_SERVICE_CHECK_RESULT;localhost;HTTP;0;HTTP OK: HTTP/1.1 200 OK - 453 bytes in 0,001 second response time
[1339598868] Warning:  Passive check result was received for service 'HTTP' on host 'localhost', but the host could not be found!
```
Se invece va tutto bene troverete nel log questi messaggi:
```txt
[1339599272] EXTERNAL COMMAND: PROCESS_SERVICE_CHECK_RESULT;base-icinga;Current Users;0;USERS OK - 1 users currently logged in
[1339599277] PASSIVE SERVICE CHECK: base-icinga;Current Users;0;USERS OK - 1 users currently logged in
```
e dall'interfaccia di Icinga vedrete cambiare lo stato dei vari servizi remoti :)
