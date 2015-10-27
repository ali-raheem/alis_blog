---
layout: post
title:  "Simple C optimization tricks"
date:   2015-10-27 16:32:25
categories: c optimization
---

While talking to a user on reddit about their code I mentioned that it's usually better for your for loop to count down to zero from the result of a function call then count up to it. And they asked why?

It's a bit difficult to explain why unless you're an assembly programer (in which case it is obvious), but seeing what gcc does with both of them will help.

Lets look at the first case shown here:
{% highlight c %}
for(i = 0; i < strlen(l); i++)
{% endhighlight %}

This generated code .L3 through .L2, in .L2 the first half checks to see if it should jumpt back to .L3 this is in effect the i <strlen(l) bit.

{% highlight gas %}
.L2:
        movl    -28(%rbp), %ebx
        movq    -24(%rbp), %rax
        movq    %rax, %rdi
        call    strlen
        cmpq    %rax, %rbx
        jb      .L3
{% endhighlight %}

It's clear to see it's 6 instructions long and includes a function call at very least a return.

{% highlight c %}
for(i = strlen(l); i > 0; i++)
{% endhighlight %}

This generated code .L5 to .L3

{% highlight gas %}
.L4:
	cmpl	$0, -28(%rbp)
	jne	.L5
{% endhighlight %}

Wow night and day... We simply check i compared to 0. Had this been the old days we may have even used [LOOP _LABEL](http://www.c-jump.com/CIS77/reference/ISA/DDU0103.html) which is dec ecx and jne to _LABEL.

CX was always a register designed to handle loops and counters.

Here is the code and output in it's entirity.

{% highlight c %}
#include <stdio.h>
#include <string.h>

int main(){
	unsigned int i;
	char *l = "abcdef";
	for(i = 0; i < strlen(l); i++){
		printf("%u\n", i);
	}

	for(i = strlen(l); i ; ++i){
		printf("%u\n", i);
	}
}
{% endhighlight %}

Which gcc -S compiles to this assembly code here.

{% highlight asm %}
	.file	"test.c"
	.section	.rodata
.LC0:
	.string	"abcdef"
.LC1:
	.string	"%u\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset 3, -24
	movq	$.LC0, -24(%rbp)
	movl	$0, -28(%rbp)
	jmp	.L2
.L3:
	movl	-28(%rbp), %eax
	movl	%eax, %esi
	movl	$.LC1, %edi
	movl	$0, %eax
	call	printf
	addl	$1, -28(%rbp)
.L2:
	movl	-28(%rbp), %ebx
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	strlen
	cmpq	%rax, %rbx
	jb	.L3
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	strlen
	movl	%eax, -28(%rbp)
	jmp	.L4
.L5:
	movl	-28(%rbp), %eax
	movl	%eax, %esi
	movl	$.LC1, %edi
	movl	$0, %eax
	call	printf
	addl	$1, -28(%rbp)
.L4:
	cmpl	$0, -28(%rbp)
	jne	.L5
	movl	$0, %eax
	addq	$24, %rsp
	popq	%rbx
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 5.2.1-22ubuntu2) 5.2.1 20151010"
	.section	.note.GNU-stack,"",@progbits
{% endhighlight %}

Enjoy,

Ali
