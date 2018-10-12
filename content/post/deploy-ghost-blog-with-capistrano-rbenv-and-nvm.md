+++
author = "Tommaso Visconti"
categories = ["ghost", "capistrano", "node", "rbenv", "nvm"]
date = 2014-04-01T12:59:14Z
description = ""
draft = false
slug = "deploy-ghost-blog-with-capistrano-rbenv-and-nvm"
tags = ["ghost", "capistrano", "node", "rbenv", "nvm"]
title = "Deploy ghost blog with capistrano, rbenv and nvm"

+++

I just moved this blog from [Jekyll](http://jekyllrb.com/) to [Ghost](https://ghost.org/) (**v.0.4.2** while writing this post) and I had to find a fast way to deploy new changes to the server.
I'm pretty confident with [Capistrano](http://capistranorb.com/) so, although Ghost doesn't use Ruby, I decided to use it to manage deployments.
A cool gem allow node apps to be deployed with Capistrano: [capistrano-node-deploy](https://github.com/loopj/capistrano-node-deploy)

This is the `Gemfile`:
```
source 'https://rubygems.org'
gem 'capistrano', '~> 2.15.5'
gem 'capistrano-node-deploy', '~> 1.2.14'
gem 'capistrano-shared_file', '~> 0.1.3'
gem 'capistrano-rbenv', '~> 1.0.5'
```
If you don't use [rbenv](https://github.com/sstephenson/rbenv) just remove the related line in the `Gemfile` and change the `Capfile` accordingly.

This configuration works well, but it has some problem if you use [nvm](https://github.com/creationix/nvm) instead of a system-wide installation of node and npm.

To fix them I had to add some variables (`nvm_path`, `node_binary` and `npm_binary`) and totally override the `node:install_packages` task. Whithout this changes the deploy task ends with messages like:

```
/usr/bin/env: node
No such file or directory
```
or: 
```
node: not found
```

This isn't really a good way, because you must change the `nvm_path` every time you upgrade nvm, but it's the only way I actually found :)

I also changed the `app_command` variable to launch `node ~/apps/tommyblue.it/current/index` instead of `node ~/apps/tommyblue.it/current/core/index` in the upstart script. The second command doesn't actually works although is the gem's default.

This is the full content of the `Capfile` (remember to change <UPPERCASE VALUES> to your own):

```prettyprint lang-ruby
require "capistrano/node-deploy"
require "capistrano/shared_file"
require "capistrano-rbenv"
set :rbenv_ruby_version, "2.1.1"

set :application, "tommyblue.it"
set :user, "<USERNAME>"
set :deploy_to, "/home/#{user}/apps/#{application}"

set :app_command, "index"

set :node_user, "<USERNAME>"
set :node_env, "production"
set :nvm_path, "/home/<USERNAME>/.nvm/v0.10.26/bin"
set :node_binary, "#{nvm_path}/node"
set :npm_binary, "#{nvm_path}/npm"

set :use_sudo, false
set :scm, :git
set :repository,  "<GIT REPO URL>"

default_run_options[:pty] = true
set :ssh_options, { forward_agent: true }

server "<SERVER HOSTNAME OR IP>", :web, :app, :db, primary: true

set :shared_files,    ["config.js"]
set :shared_children, ["content/data", "content/images"]

set :keep_releases, 3

namespace :deploy do
  task :mkdir_shared do
    run "cd #{shared_path} && mkdir -p data images files"
  end

  task :generate_sitemap do
    run "cd #{latest_release} && ./ghost_sitemap.sh #{latest_release}"
  end
end

namespace :node do
  desc "Check required packages and install if packages are not installed"
  task :install_packages do
    run "mkdir -p #{previous_release}/node_modules ; cp -r #{previous_release}/node_modules #{release_path}" if previous_release
    run "cd #{release_path} && PATH=#{nvm_path}:$PATH #{npm_binary} install --loglevel warn"
  end
end

after "deploy:create_symlink", "deploy:mkdir_shared"
after "node:restart", "deploy:generate_sitemap"
after "deploy:generate_sitemap", "deploy:cleanup"
```