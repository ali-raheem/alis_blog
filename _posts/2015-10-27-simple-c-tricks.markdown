---
layout: post
title:  "Simple C optimization tricks"
date:   2015-10-27 16:32:25
categories: c optimization
---

While talking to a user on reddit about their code I mentioned that it's usually better for your for loop to count down to zero from the result of a function call then count up to it. And they asked why?

It's a bit difficult to explain why unless you're an assembly programer (in which case it is obvious), but seeing what gcc does with both of them will help.

To that end I've created a simple C file and then used gcc -S to translate it to assembler. Both listings are at the bottom of the post but I'll show snippets of the relevent parts as needed.

Lets look at the first case shown here:

{% highlight c %}
for(i = 0; i < strlen(l); i++)
{% endhighlight %}

This was translated to the assemler code .L3 through .L2, in .L2, the first half checks to see if it should jumpt back to .L3 this is in effect the i <strlen(l) bit.
In the following code snipper -36(%rbp) is i, rbp is the base pointer which points to the base of the current frame, rsp is the stack pointer this points to the top of stack which will chase with pop/push's. -36(%rbp) is 28 bytes offset from rbp, the stack grows down so the address of i is lower than the base of the stack. -32(%rbp) is the address of the string we pass to strlen.

{% highlight gas %}
.L2:
	movl	-36(%rbp), %eax
	movslq	%eax, %rbx
	leaq	-32(%rbp), %rax
	movq	%rax, %rdi
	call	strlen
	cmpq	%rax, %rbx
	jb	.L3
{% endhighlight %}

It's clear to see it's 7 instructions long and includes a function call at very least a return. The first two instructions load rbx with i via eax. ebx is the 32bit register while rbx is the 64bit register. Now rax is loaded with the pointer (effective address) to the string which is passed to strlen via rdi ([the 64bit calling convention on sysv puts the first int argument in rdi](https://en.wikipedia.org/wiki/X86_calling_conventions#x86-64_calling_conventions)).
The result of strlen (in rax) is compared to rbx (i). Finally jump if rax > rbx to .L3

{% highlight c %}
for(i = strlen(l); i >= 0; --i)
{% endhighlight %}

This generated code .L5 to .L3

{% highlight gas %}
.L4:
	cmpl	$0, -36(%rbp)
	jns	.L5
{% endhighlight %}

Wow night and day... We simply compare i to 0 and [jump if not sign](https://en.wikipedia.org/wiki/Sign_flag) to .L5.

Had this been the old days we may have even used [LOOP _LABEL](http://www.c-jump.com/CIS77/reference/ISA/DDU0103.html) which is dec ecx and jz to _LABEL.

CX was always a register designed to handle loops and counters. However in the system v calling convention [RCX is designated caller save](https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI) so may be clobbered by strlen().

One thing to note is that I wanted to compare pre and post increment effectiveness, in the past and certainly still in some embedded toolchains this can result in poor code because the compiler may not be smart enough to omptimize away the result from a post incrememnt.

Here is the code and output in it's entirity.

{% highlight gas %}
	.file	"test.c"
	.section	.rodata
.LC0:
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
	subq	$40, %rsp
	.cfi_offset 3, -24
	movq	%fs:40, %rax
	movq	%rax, -24(%rbp)
	xorl	%eax, %eax
	movl	$1684234849, -32(%rbp)
	movw	$26213, -28(%rbp)
	movb	$0, -26(%rbp)
	movl	$0, -36(%rbp)
	jmp	.L2
.L3:
	movl	-36(%rbp), %eax
	movl	%eax, %esi
	movl	$.LC0, %edi
	movl	$0, %eax
	call	printf
	addl	$1, -36(%rbp)
.L2:
	movl	-36(%rbp), %eax
	movslq	%eax, %rbx
	leaq	-32(%rbp), %rax
	movq	%rax, %rdi
	call	strlen
	cmpq	%rax, %rbx
	jb	.L3
	leaq	-32(%rbp), %rax
	movq	%rax, %rdi
	call	strlen
	movl	%eax, -36(%rbp)
	jmp	.L4
.L5:
	movl	-36(%rbp), %eax
	movl	%eax, %esi
	movl	$.LC0, %edi
	movl	$0, %eax
	call	printf
	subl	$1, -36(%rbp)
.L4:
	cmpl	$0, -36(%rbp)
	jns	.L5
	movl	$0, %eax
	movq	-24(%rbp), %rdx
	xorq	%fs:40, %rdx
	je	.L7
	call	__stack_chk_fail
.L7:
	addq	$40, %rsp
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

If you're interested here's a quick overview of the above assembly code.

The first thing to note is that this is the main function _start is provided by libc. The begining of any function in assmbly should be saving any callee save registers that we may clobber on systemv this is rbp, rbx, r12-r15. We don't use r12-r15 so we push rbp and rbx on the stack and pop them off before our ret at .L7. Once this is done we overwrite the base pointer rbp with our stack pointer rsp then "make room on the stack" by moving the rsp down by 40 for our automatic variables which are at offsets -24, -28, -32 and -36 (each are 4 bytes long).

This code was compiled with a [stack-protector](https://lwn.net/Articles/584225/), this dubious honour was applied because we have a char array. We're actually at no risk of a stack smash but it seems gcc has been setup to be fairly paranoid when Ubuntu compiled it, possibly with -fstack-protector-strong. Traditionally -fstack-protector only added protrotection if a 8 byte or larger char array was created. Stack-protector uses a canary (secret random integer) infront of the return address thus our first "automatic variable" is actually preloaded with this from %fs:40. This is random, if you want to see it's contents simply alter .L2 to load it into eax instead of i. Thus, `movl -36(%rbp), eax` would become `movl -24(%rbp), eax` and we'll see it printed in the first for loop. It should change each time you run the program, thus it would be unknown to an outside attacker. Not only this but it's value is stored out of the memory mapped to the process (hence the use of %fs - file segment), this way a segmentation fault should occur if someone tries to clumsily access it.

Canaries need not be random, youalso get "terminator" canaries, not as cool a they sound these are made up o fbytes designed to terminate functions which take input that may be venerable such as gets(). These are made up of a NULL byte (to stop strcpy()), DEL to make string inputs difficult and newline bytes \r\n which will terminate gets() input. Pretty clever.

The idea being that if the attacker wishes to overwrite our return address they will need to go through our canary. So, at the end of the the main function the latter half of .L4, we will reload it from %fs:40 and then compare it to -24(%rbp) if they don't match then at some point in the main function it was altered since GCC added it in addition to the variables we wanted this means the "stack has been smashed" i.e. for some reason we wrote some code out of bounds. If this is the case GCC has added in a jump to __stack_chk_fail this way we will not return from main but abort.

Had the return address been overwritten and should we return from main there is a risk we would be handing control of execution to an attacker.

If all is well we restore our saved registers by pop'ing them off the stack and then return to libc's _start ([_start_main](http://refspecs.linuxbase.org/LSB_3.1.1/LSB-Core-generic/LSB-Core-generic/baselib---libc-start-main-.html)) who will pass control to an exit function.

The rest of the code is simply providing arguments to printf and strlen and simple counter stuff.

Enjoy,

Ali
