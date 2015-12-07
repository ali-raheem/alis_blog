---
layout: post
title:  "Security upgrade"
date:   2015-11-25-11-49-00
categories: site
---

I've recently done a security overhaul of the site disabling weak and vunerable SSL settings and ciphers.

We also sport a fancy custom DH parameters... snazzy!

[We've gone from a SSL labs B to an A+](https://www.ssllabs.com/ssltest/analyze.html?d=theraheemfamily.co.uk). :) But as you can see many older and weaker devices wont like it.

If you are having problems (don't worry you cant read this since I have HSTS) if you can but it complains, seriously, update your browser!!

Here is the settings I used. [weakdh.org](https://weakdh.org/sysadmin.html).

Enjoy,
Ali
