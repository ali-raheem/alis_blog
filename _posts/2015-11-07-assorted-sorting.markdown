---
layout: post
title:  "Assorted sorts"
date:   2015-11-07-00-01-00
categories: c sorting algorithms
---

I was reading through [Jamsa's C/C++ Programmers Bible - The Ultimate Guide to C/C++ Programming](http://www.amazon.co.uk/Jamsas-Programmers-Bible-Kris-Jamsa/dp/0766846822), a book I bought for a couple of quid from a charity shop in 2005 and never touched! and I thought I'd do a quick series on sorting algorithms written in C. The book goes over bubble sorting, shell sorting and quick sorting but the examples it provides are:

1. Not at all generic
2. Not optimised

Which I understand, it's probably designed to be simple and easy to understand but I thought it'd be a good exercise to implement them properly

I started with a bubble_sort the simplest and literally the worst sort according to Wikipedia.

Personally I always use qsort because it's very effective and is only weakness is it's a bit more complex (but included in libc so who cares) and a bit slower if you have a pre-sorted or very short list.

A bubble sort is simple, starting at one end of an array it swaps a element with the next one if they are out of order, it continues along the array like this. It's name comes from the way a bubble might rise in a glass of beer.

It moves an element until it encounters a bigger one then starts to work that one up.

Each pass is guaranteed to move the biggest unsorted element to the correct location. It then works on the rest of the array restarting at the bottom.

If during a pass no swaps are made you can bale out and know you're done.

Here is the function in a snippet:

{% highlight c %}
void bubble_sort (void *array, size_t nmemb, size_t size, int (*compar)(const void *, const void *)) {
  int i, j;
  int swap = 0;
  void *temp, *a, *b;
  temp = malloc(size);
  for(i = nmemb - 1; 0 <= i; --i) {
    swap = 0;
    for(j = nmemb - 1; 0 <= j; --j) {
      if(i == j)
      	continue;
      a = array+i*size;
      b = array+j*size;
      if(1 == compar(a, b)) {
	swap = 1;
	memcpy(temp, a, size);
	memcpy(a, b, size);
	memcpy(b, temp, size);
      }
    }
    if(0 == swap)
      break;
  }
  free(temp);
}
{% endhighlight %}

It's very generic which requires you pass it the size of the elements and a comparison function (which should return 1, 0, -1 ala strcmp). Notice therefore we need to use memcpy to move elements around.

{% highlight c %}
int person_cmp (const void *a, const void *b) {
  Person *da = (Person *) a;
  Person *db = (Person *) b;
  int ca = da->age;
  int cb = db->age;
  return (ca < cb) ? -1 : (ca > cb);
}
{% endhighlight %}

This is the comparison function, our bubble_sort passes it void * but it's messy to continuously be dereferencing null pointers so we sanitise them to (Person *). Then we simply somehow come up with a way to compare them. The return statement I use is the easiest way and the compiler should handle it very well.

Actually I checked it and it gcc performed excellently.

{% highlight gas %}
	cmpl	%eax, %edx
	jb	.L2
	movl	-16(%rbp), %edx
	movl	-12(%rbp), %eax
	cmpl	%eax, %edx
	seta	%al
	movzbl	%al, %eax
	jmp	.L4
.L2:
	movl	$-1, %eax
.L4:
;clear up and return
{% endhighlight %}

This is what I mean by writing good portable assembler C, that and a good compiler produces exactly what a good human programmer would come up with.

This is kind of signature is super powerful and good enough for small or nearly sorted arrays. According to Wikipedia insertion sorts although more complex perform better in both these areas.

The following code snippet uses the same bubble sort to sort string and then a contrived array of "Person" structs by age using a simple custom person_compar function.

I'll write up another sorting method soon.

Enjoy,

Ali

The code in it's entirety:

{% highlight c %}
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

struct person_s {
  char *name;
  unsigned int age;
};
typedef struct person_s Person;

void bubble_sort (void *array, size_t nmemb, size_t size, int (*compar)(const void *, const void *)) {
  int i, j;
  int swap = 0;
  void *temp, *a, *b;
  temp = malloc(size);
  for(i = nmemb - 1; 0 <= i; --i) {
    swap = 0;
    for(j = nmemb - 1; 0 <= j; --j) {
      if(i == j)
      	continue;
      a = array+i*size;
      b = array+j*size;
      if(1 == compar(a, b)) {
	swap = 1;
	memcpy(temp, a, size);
	memcpy(a, b, size);
	memcpy(b, temp, size);
      }
    }
    if(0 == swap)
      break;
  }
  free(temp);
}

int person_cmp (const void *a, const void *b) {
  Person *da = (Person *) a;
  Person *db = (Person *) b;
  int ca = da->age;
  int cb = db->age;
  return (ca < cb) ? -1 : (ca > cb);
}

int char_cmp (const void *a, const void *b) {
  char ca = *(char *) a;
  char cb = *(char *) b;
  return (ca < cb) ? -1 : (ca > cb);
}

int int_cmp (const void *a, const void *b) {
  int ca = *(int *) a;
  int cb = *(int *) b;
  return (ca < cb) ? -1 : (ca > cb);
}

int main (int argc, char **argv) {
  char list[] = "badec";
  printf("We start with %s\n", list);
  bubble_sort(list, strlen(list), sizeof(char), char_cmp);
  printf("bubble_sort gives us %s\n", list);
  int n = 8;
  Person contacts[n];
  srand(time(NULL));
  int i, j;
  for(i = n; 0 <= i; --i) {
    char *name = malloc(n);
    for(j = n - 1; 0 <= j; --j) {
      name[j] = 'a' + rand()%26;
    }
    name[n] = 0;
    contacts[i].name = name;
    contacts[i].age = rand() % 99;
  }
  puts("How about something more interesting\nWe start with this list of random names and ages...");
  for(i = 0; n > i; ++i) {
    printf("%s is %u years old.\n", contacts[i].name, contacts[i].age);
  }
  bubble_sort(contacts, 8, sizeof(Person), person_cmp);
  puts("bubble_sort gives us this list");
  for(i = 0; n > i; ++i) {
    printf("%s is %u years old.\n", contacts[i].name, contacts[i].age);
  }
}
{% endhighlight %}

