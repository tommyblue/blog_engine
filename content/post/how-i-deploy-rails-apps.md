+++
author = "Tommaso Visconti"
categories = ["informatica", "how-to", "rails", "ruby", "unicorn", "supervise", "rbenv", "capistrano", "nginx"]
date = 2013-07-17T13:18:07Z
description = ""
draft = false
slug = "how-i-deploy-rails-apps"
tags = ["informatica", "how-to", "rails", "ruby", "unicorn", "supervise", "rbenv", "capistrano", "nginx"]
title = "How I deploy Rails apps"

+++



In various mailing lists I read a lot of threads about deploying a Rails app. I want to contribute to the topic with this post, where I'll describe how I'm now deploying my rails apps in a VPS (actually it's not a virtual but a physical server, but it's the same..).

In the past I used [Pushion Passenger](https://www.phusionpassenger.com/) but it was a very young project and when [Unicorn](http://unicorn.bogomips.org/) showed up, I felt in love :)
I wrote a [similar post](http://www.tommyblue.it/2009/11/14/deploy-di-applicazioni-rails-con-unicorn-e-nginx) some years ago, the idea is the same, but the structure is now more solid.

The tools I'm now using are:

- Unicorn as Rack HTTP server
- [Nginx](http://nginx.org/) as proxy server
- Supervise (part of Daemontools) to monitor the unicorn app
- [Capistrano](https://github.com/capistrano/capistrano) to manage the deploy
- [Rbenv](https://github.com/sstephenson/rbenv) to manage the ruby environment

The server's o.s. is Ubuntu 12.04 LTS.

## Rbenv

To install rbenv and ruby-build:

    sudo apt-get install build-essential zlib1g-dev openssl libopenssl-ruby1.9.1 libssl-dev libruby1.9.1 libreadline-dev git-core
    git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    exec $SHELL -l
    mkdir -p ~/.rbenv/plugins
    cd ~/.rbenv/plugins
    git clone git://github.com/sstephenson/ruby-build.git
    rbenv install 2.0.0-p247
    rbenv rehash
    rbenv global 2.0.0-p247
    rbenv local 2.0.0-p247

Just check if everything went ok:

	$ ruby -v
	ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-linux]

Read [this post](http://robots.thoughtbot.com/post/47273164981/using-rbenv-to-manage-rubies-and-gems) to switch to Rbenv if you're using [RVM](https://rvm.io/)

## Capistrano

Create the required folder in the server:

	mkdir ~/apps

Now configure your app to be deployed:

	cd ~/my_app_path
	echo "gem 'capistrano'" >> Gemfile
	bundle install
	capify .

edit the *Capfile* file if you need, then edit *config/deploy.rb*. This is a working example:

```prettyprint lang-ruby

require "bundler/capistrano"
require "capistrano-rbenv"
set :rbenv_ruby_version, "2.0.0-p247"

set :user, "server_username"
set :application, "my_app"
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache

set :use_sudo, false
set :scm, :git
set :repository,  "your_app_git_repo"

default_run_options[:pty] = true
set :ssh_options, { forward_agent: true }

server "my_server.my_domain", :web, :app, :db, primary: true

set :branch, "master"
set :rails_env, "production"

after "deploy", "deploy:cleanup" # keep only the last 5 releases

# Daemontools start/stop
namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      if command == "start"
        sudo "/usr/bin/svc -u /etc/service/my_app"
      elsif command == "stop"
        sudo "/usr/bin/svc -d /etc/service/my_app"
      else
        sudo "/usr/bin/svc -t /etc/service/my_app"
      end
    end
  end

  task :setup_config, roles: :app do
    run "mkdir -p #{shared_path}/config"
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      puts "WARNING: HEAD is not the same as origin/#{branch}"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"
end

```


You can create the required folders with:

	cap deploy:setup

Log in to the server and check the *~/apps/my_app/shared* folder. Add these folders if they don't exist:

	cd ~/apps/my_app/shared
	mkdir config logs pids sockets

in the _config_ folder create a _database.yml_ file with the rails production environment configurations.

## Unicorn

Add the unicorn gem to the rails app:

	cd ~/my_app_path
	echo "gem 'unicorn'" >> Gemfile
	bundle install

Add the unicorn configuration in the _shared/config/unicorn.rb_ file (in the server):

```prettyprint lang-ruby

worker_processes 2
working_directory "/home/my_user/apps/my_app/current" # available in 0.94.0+
listen "/home/my_user/apps/my_app/shared/sockets/my_app.sock", :backlog => 64
timeout 30
pid "/home/my_user/apps/my_app/shared/pids/unicorn.pid"
stderr_path "/home/my_user/apps/my_app/shared/log/unicorn.stderr.log"
stdout_path "/home/my_user/apps/my_app/shared/log/unicorn.stdout.log"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end

```


To launch unicorn I create the _~/service_ folder. There I create a folder for each project. So:

	mkdir -p ~/service/my_app

Then the required files.

**~/service/my_app/run (must be executable)**

```prettyprint lang-bash

#!/bin/bash

exec su - my_user -c '/home/my_user/service/load_my_app.sh bundle exec unicorn_rails -E production -c /home/my_user/apps/my_app/shared/config/unicorn.rb'
# If you want to launch unicorn manually use te line below instead of the line above (use sudo!). Useful for debugging
# exec su - my_user -c '/home/my_user/service/load_my_app.sh bundle exec unicorn_rails -E production -l /home/my_user/apps/my_app/shared/sockets/my_app.sock'

```


**~/service/load_my_app.sh**

```prettyprint lang-bash

#!/bin/bash

export RAILS_ENV="production"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
cd /home/my_user/apps/my_app/current/
exec $@

```


As pointed in the comment, you can use the _run_ file to test the app, just modify the file then launch it as root:

	cd ~/service/my_app
	sudo ./run

You'll see the familiar unicorn startup process, then it will listen for connections in the given socket.

That's it, now jump to supervise

## Daemontools

Install the required packages:

	sudo apt-get install daemontools daemontools-run

After this command you'll have the _svc_ executable. Before using it, create the symbolic link in the _/etc/service_ folder:

	cd /etc/service
	sudo ln -s /home/my_user/service/my_app

Supervise automatically launches, at server sturtup, the _run_ executable in the folders present in _/etc/service/_

To manually startup the app, use _svc_:

	sudo svc -u /etc/service/my_app

This is the same command used by capistrano during deploy (se configuration above).

## Nginx

If everything went as expected, the rails app is running and listening for connections in the unix socket at */home/my_user/apps/my_app/shared/sockets/my_app.sock*. Now configure Nginx to use that socket.

**/etc/nginx/sites-available/www.my_app.my_domain**

```prettyprint lang-nginx

upstream backend_my_app {
  server unix:/home/my_user/apps/my_app/shared/sockets/my_app.sock fail_timeout=0;
}

server {
	listen [::]:80;

  client_max_body_size 4G;
  keepalive_timeout 5;

  try_files $uri/index.html $uri.html $uri @app;

	root /home/my_user/apps/my_app/current/public/;
	index index.html index.htm;

	server_name my_app.my_domain www.my_app.my_domain;

  location @app {
    gzip_static on;
    proxy_pass http://backend_my_app;
    proxy_redirect off;

    proxy_set_header        Host    $host;
    proxy_set_header        X-Real-IP       $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto $scheme;

    root /home/my_user/apps/my_app/current/public/;
    index  index.html index.htm;
  }

  location ~* ^/font.+\.(svg|ttf|woff|eot)$ {
    root /home/my_user/apps/my_app/current/public/;
  }

  error_page   500 502 503 504  /50x.html;
  location = /50x.html {
    root   /var/www/nginx-default;
  }

  access_log  /var/log/nginx/access.log;
  error_log  /var/log/nginx/error.log;
}

```


Symlink this file in */etc/nginx/sites-enabled/* and restart nginx, your app should be online.

When you'll deploy a new version of the app, Capistrano will require the sudo password to send a TERM signal to supervise, which will restart the rails app.

That's it, it seems a lot of configuration (and maybe is) but it works great and there are very little differences between the projects, so **CTRL-C+CTRL-V** works great! :)
