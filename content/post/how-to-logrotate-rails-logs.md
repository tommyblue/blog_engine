+++
author = "Tommaso Visconti"
categories = ["rails", "logs", "deploy"]
date = 2014-04-11T06:59:27Z
description = ""
draft = false
slug = "how-to-logrotate-rails-logs"
tags = ["rails", "logs", "deploy"]
title = "How to logrotate rails logs"

+++

If you deploy a rails app forgetting to configure logs automatic rotation, few weeks later won't be difficult to find something like this:

```
$ ls -lh log/production.log
  -rw-rw-r-- 1 www-data www-data 93,2M apr 10 17:49 production.log
```

Think if you have to find some error log inside a 100MB file, not easy... :)

Setting log rotation isn't difficult at all. I know two main ways.

## Use syslog
This is a really easy solution. Rails will use standard syslog as logger, which means the logs will rotate automatically.

Open `config/environments/production.rb` and add this line:

```prettyprint lang-ruby
config.logger = SyslogLogger.new
```

If you want to avoid your logs to be mixed with system logs you need to add some parameters:

```prettyprint lang-ruby
config.logger = SyslogLogger.new('/var/log/<APP_NAME>.log')
```

## Use logrotate
This is the cleaner way, but requires to create a file in the server, inside the `/etc/logrotate.d/` folder. This is a possible content of the `/etc/logrotate.d/rails_apps` file:

```
/path/to/rails/app/log/*.log {
    weekly
    missingok
    rotate 28
    compress
    delaycompress
    notifempty
    copytruncate
}
```

The `copytruncate` option is required unless you want to restart the rails app after log rotation. Otherwise the app will continue to use the old log file, if it exists, or will stop logging (or, worse, will crash) if the file is deleted.
Below the `copytruncate` details from [the logrotate man page](http://linuxcommand.org/man_pages/logrotate8.html):

```
copytruncate
      Truncate  the  original log file in place after creating a copy,
      instead of moving the old log file and optionally creating a new
      one,  It  can be used when some program can not be told to close
      its logfile and thus might continue writing (appending)  to  the
      previous log file forever.  Note that there is a very small time
      slice between copying the file and truncating it, so  some  log-
      ging  data  might be lost.  When this option is used, the create
      option will have no effect, as the old log file stays in  place.
```

To check the logrotate script you can use the `logrotate` command with the debug (`-d`) option, which executes a dry-run:
```prettyprint lang-bash
sudo logrotate -d /etc/logrotate.d/rails_apps
```

If everything seems ok you can wait until the next day or manually launch the rotation with:
```prettyprint lang-bash
sudo logrotate -v /etc/logrotate.d/rails_apps
```