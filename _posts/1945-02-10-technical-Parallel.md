---
layout: post
title: "Parallel Execution"
date: 1945-02-10 00:00
comments: true
categories: technical
---

Modern CPUs typically contain multiple real cores (processing units that share memory), and a PC may contain more than one CPU.
Some chips also implement "virtual" cores which help allow the compiler to keep the hardware working while one process is data limited.

umx allows you to get and set the number of cores OpenMx will use with:

```splus
umx_get_cores() # how many cores are we currently requesting?
umx_set_cores() # defaults to max-1
umx_set_cores(n)

```

You can see total number of cores on your machine with `detectCores()` (on my 2015 MacBook, the answer is 4).

Out of the box, OpenMx uses `mxDetectCores() - 1` to execute in parallel on supported OS's.

You can change this using an option

```splus
mxOption(NULL, "Number of Threads", n)
```

This involves remembering the correct option string.


You may find `umx_set_cores` easier, especially with the [TextMate](http://macromates.com) bundle or R's function completion (just type `umx_` and tab to see the list…):

So this

```splus
umx_set_cores() # defaults to max-1
```

is equivalent to:

```splus
mxOption(NULL, "Number of Threads", detectCores() - 1)
```

Support for multiple cores is expected on all platforms during 2016, and will dramactically speed up time consuming processing, like CIs.