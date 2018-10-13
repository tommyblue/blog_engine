+++
author = "Tommaso Visconti"
categories = ["ghost", "capistrano"]
date = 2014-04-02T07:53:27Z
description = ""
draft = false
slug = "generate-the-sitemap-of-a-ghost-blog-during-deploy"
tags = ["ghost", "capistrano"]
title = "Generate the sitemap of a Ghost blog during deploy"

+++

Waiting for a sitemap generator inside the core of [Ghost](https://ghost.org/) (planned as *["future implementation"](https://github.com/TryGhost/Ghost/wiki/Planned-Features)*) I decided to implement a way to generate an up-to-date `sitemap.xml` during deployment.
As you can read in the [previous post](/2014/04/01/deploy-ghost-blog-with-capistrano-rbenv-and-nvm/) I'm deploying this blog with [Capistrano](http://capistranorb.com/) and [capistrano-node-deploy](https://github.com/loopj/capistrano-node-deploy).
So I added a `deploy:generate_sitemap` task which is executed at the end of the deployment process.

This is the `Capfile` extract:

```ruby
namespace :deploy do
  task :generate_sitemap do
    run "cd #{latest_release} && ./ghost_sitemap.sh #{latest_release}"
  end
end
after "node:restart", "deploy:generate_sitemap"
```

So at the end of the deployment the `ghost_sitemap.sh` script is executed. The script is placed in the blog root and is a personalized version of the code you can find here: http://ghost.centminmod.com/ghost-sitemap-generator/

It essentially does 3 things:

- Puts the `sitemap.xml` link in the `robots.txt` file
- Scans (using `wget`) the website and generates the `sitemap.xml` file in the `content` folder
- Notifies [Google Webmaster Tools](https://www.google.com/webmasters/tools/home)

What I changed of the original script is:

```ini
url="www.tommyblue.it"
webroot="${1}/content"
path="${webroot}/sitemap.xml"
user='<USER>'
group='<GROUP>'
```

`user` and `group` will be used to `chmod` the `sitemap.xml` file, so check that the web user (probably `www-data`) can read that file.

This process has a big problem: the sitemap is generated only during deploy, not when I publish a new post. A workaround is to run `cap deploy:generate_sitemap` after a new post is published.

It works but I need an automatic way. Any idea?
