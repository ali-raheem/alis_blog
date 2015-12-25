---
layout: post
title:  "Secure deterministic passwords"
date:   2015-12-24-22-14-00
categories: site
---

I use TAILS for about 90% of my browsing no matter what it is, reading reddit.com, checking someone out on wikipedia or even reading the news.

This way I don't need to bother with my worrying about leaving a footprint.

The only problem is I end up with a million different throwaway accounts I couldn't touch again if I wanted (they have weak password but I've forgotten them). Usually I know where they are, for example, user not_a_real_account on reddit.com. But what on earth did I use for the password?

To get past this issue I made a super simple python script that lets your input a "seed" or "master password" and then have it make unique passwords for each url and username combination.

Effectively it takes a slice from the hexdigest from a SHA512 of the concantrated username, url and SHA512 of the seed.

{% highlight python %}
#!/usr/bin/env python
import hashlib, getpass

seed = getpass.getpass('Seed: ')
hseed = hashlib.sha512()
hseed.update(seed)
hseed = hseed.hexdigest()
seed = ''
while 1:
      url = raw_input('URL: ')
      uname = raw_input('username: ')
      passwd = hashlib.sha512()
      passwd.update(url)
      passwd.update(uname)
      passwd.update(hseed)
      print passwd.hexdigest()[0:24]
{% endhighlight %}

This script is all you need, and this page is an easy place to find it. You could even put it on your own little gist.

Hence forth you can have good security without the baggae of carrying around your keepass database or persistance volume.

The passwords by default at 24 characters long and since they are made up with hexidecimal my password quaility estimator gives us a typical 96 bits security (ln(16)/ln(2)*24).

Now all you need to remember is how to find the username.

Please get in touch with me if you see a weakness in this. The security depends entirely on the quaility of your seed since the url is guessible and the username is known.

Check out my previous posts for an example of a strong seed/passphrase that will net you >200bits of security.

Enjoy your new privacy!

Ali