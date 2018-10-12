+++
author = "Tommaso Visconti"
categories = ["informatica", "software libero", "github", "ruby", "bind", "dns"]
date = 2012-04-03T13:34:43Z
description = ""
draft = false
slug = "bind-log-analyzer-simple-analysis-and-sql-storage-for-bind-dns-server-logs"
tags = ["informatica", "software libero", "github", "ruby", "bind", "dns"]
title = "Bind Log Analyzer: Simple analysis and SQL storage for Bind logs"

+++



![Bind Log Analyzer web interface](http://f.cl.ly/items/0A1A173R3b012R1V2x2b/bind_log_analyzer_screenshot_1.jpg)

Bind Log Analyzer is my first gem :)

It analyzes a Bind query log file and stores the logs into a database (using ActiveRecord). See the details and the source code on [GitHub](https://github.com/tommyblue/Bind-Log-Analyzer) and get the gem on [RubyGems](https://rubygems.org/gems/bind_log_analyzer). Or simply install it with:

    gem install bind_log_analyzer
    
Starting from version 0.2.1 it includes a simple [Sinatra](http://www.sinatrarb.com/) webserver to show some reports and (soon) some cool graphs.
