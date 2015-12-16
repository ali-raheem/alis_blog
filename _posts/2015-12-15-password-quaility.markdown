---
layout: post
title:  "Password quaility estimation"
date:   2015-12-15-23-56-00
categories: site
---

I thought I'd have a quick look at the quaility of my passwords. Not my main passwords these are all managed by KeePassX and are ridiculously long and random. But some of my passwords have to be simple and memorable (for example the one I use to access the KeePassX databases).

Well how do you gauge the quality of a password? We all know it should be long, not a dictionary word and involve a variety of character types. But why? It all comes down to entropy.

Simply, lets assume you don't use a dictionary password or something that could be gotten by word-mangling attacks. We have to fall back to bruteforcing and any password becomes crackable given enough time. The longer the better, other than a direct attack on you, it's likely the hacker will use a rainbow table. Without a unique salt the hacker can scan the database for matches with hashes making his life easier.

What makes a good password? It has to have high total entropy, this is roughly length * entropy per character. How do we work out the amount of entropy per character? Well that's simple actually. If we insist on random passwords and not English dictionary words then each character is equally likely and so the entropy per byte is the number of bits we need to be able to uniquely identify each char.

If our password is all lower case characters then there are 26 options and so we need at least ln(26)/ln(2) bits to encode it. ln(26)/ln(2) is 4.700 so a 8 charecter password gives us 37.604 bits of entropy (security) and 16 characters gives us 75.207 . So how much entropy is enough? Really thats up to you but it depends on the rest of your security. If you're using AES-256 theoretically your maximum security if 256 bits, and it's likely your password will the weakest link. If you password doesn't provide at least 128 bits og of security you'd be better off sticking to AES-128 since the rest is wasted. You may want to use AES-256 instead to slow down bruteforce attempts and incase you are worried about AES being broken (How likely is that??)...

Anyways, most of my memoriable passwords are over 128 bits. How? I tend to use phrases. Like "How could you hate the snow?" Over 180 bits. Now of course this isn't entirely random it's English. So if you have a "q" it's almost certainly going to be followed by a "u", in effect that "u" provides almost no entropy. But since no one, other than you ;) knows I use English phrases we're safe. If they knew this the could reduce the character set to the English words and a handful of punctuation with simple mangling (Capitalise proper nouns and first letter).

It gets tedious estimate entropy yourself, try this C snippet to do it for you, it assumes the attacker only includes certain chars to his charset in chunks, for example, he wont use lower case and "H", he'd include the entire upper case charset too. It treats punctuation and other special characters seperatly.

{% highlight c %}
#include <stdio.h>
#include <string.h>
#include <math.h>

#define LN_2 0.693

struct {
  unsigned int lower : 1;
  unsigned int upper : 1;
  unsigned int punc : 1;
  unsigned int nums : 1;
  unsigned int special : 1;
} flags;

int main(int argc, char **argv) {
  if(2 > argc) {
    printf("%s word\n", argv[0]);
    return -1;
  }

  int i;
  //  unsigned int i = strlen(argv[1]) - 1;
  for(i = 0; i < strlen(argv[1]); ++i){
    char temp = argv[1][i];
    if('A' <= temp && 'Z' >= temp)
      flags.upper = 1;
    else if('a' <= temp && 'z' >= temp)
      flags.lower = 1;
    else if('0' <= temp && '9' >= temp)
      flags.nums = 1;
    else if(' ' == temp || ',' == temp || '.' == temp)
      flags.punc = 1;
    else
      flags.special = 1;
  }
  
  unsigned int charset = 0;
  if(flags.lower)
    charset += 26;
  if(flags.upper)
    charset += 26;
  if(flags.nums)
    charset += 10;
  if(flags.punc)
    charset += 3;
  if(flags.special)
    charset += 32;

  printf("Word entropy: %G\n", strlen(argv[1]) * log(charset)/LN_2);
}
{% endhighlight %}
