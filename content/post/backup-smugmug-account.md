---
title: "Complete backup of a SmugMug account"
date: 2019-04-05T23:47:14+02:00
draft: false
author: "Tommaso Visconti"
categories: ["smugmug", "golang"]
description: ""
image: "/images/2019/04/complete-backup-of-a-smugmug-account.jpeg"
slug: "complete-backup-of-a-smugmug-account"
tags: ["smugmug", "golang"]
---

I'm a happy customer of the [SmugMug](https://www.smugmug.com/) service where I store all my photos
(~50GB divided in ~120 galleries).

I really love their interface, the mobile app, the website, etc. but they miss a very important
feature IMHO: **it's not possible to make a complete download of all the photos**.

That's why I wrote a [program](https://github.com/tommyblue/smugmug-backup) that does it.
<!--more-->

SmugMug provides a feature which allows users to download a zip archive of a gallery, but I don't
want to browse and download all of them.
Moreover, download is async: you ask for a download and you'll receive an email in a few minutes
with a link to the archive.

[SmugMug APIs](https://api.smugmug.com/) seemed promising so I decided to write my own app to
accomplish this purpose.

And I did it in a few days!

The app is written in golang, except a little util (written by SmugMug)
which requires Python3. You can find everything in my [GitHub repository](https://github.com/tommyblue/smugmug-backup).
