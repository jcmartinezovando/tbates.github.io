---
layout: post
title: "Parallel Execution"
date: 1945-02-10 00:00
comments: true
categories: technical
---

Parallel execution in OpenMx can be on mulitple cores, or distributed across distinct machines. Single models can be processed using parallel resrouces, and multiple models can be run and results combined.

Modern CPUs typically contain multiple cores ([processing units that share memory](https://en.wikipedia.org/wiki/Multi-core_processor)), and machines may contain more than one CPU.
Some chips also implement "[virtual](https://en.wikipedia.org/wiki/Hyper-threading)" cores which help allow the compiler to keep the hardware working while one process is data limited.

You can see total number of cores on your machine with `detectCores()` (on my 2015 MacBook, the answer is 4, 2 of which are virtual).

Out of the box, OpenMx uses `detectCores() - 1` to execute in parallel on supported OS's.

### Set cores with umx

*umx* allows you to get and set the number of cores OpenMx will use with:

```splus
umx_get_cores() # how many cores are we currently requesting?
umx_set_cores() # defaults to max-1
umx_set_cores(n) # request use of n-cores

```

Under the hood, this is changing an option:

```splus
mxOption(NULL, "Number of Threads", n)
```

So this

```splus
umx_set_cores() # defaults to max-1
```

is equivalent to:

```splus
mxOption(NULL, "Number of Threads", detectCores() - 1)
```

So now you don't need to remembering the correct option string.

Support for multiple cores is expected on all platforms during 2016, and will dramactically speed up time consuming processing, like CIs.

*top tip*: [TextMate](http://macromates.com) OpenMx bundle
*top tip*: Use R's tab-function completion (just type `umx_` and tab to see the list…):

### OpenMP on unix clusters

If you're trying to use mulitple cores on a managed cluster, you might need to request these in the control script that schedules your jobs.

Here's an example for edinburgh's cluster. The key is `-pe OpenMP 12`

```splus
#!/bin/sh
# This is a simple example of a batch script
# call me as
# qsub -P ppls_psychology -cwd  -o ~/bin/makeOpenMx.out -e ~/bin/makeOpenMx.err ~/bin/makeOpenMx.sh
# Grid Engine options 
#$ -cwd
# Set the maximum run time to 30 minutes, 0 seconds:
#$ -l h_rt=00:30:00
#$ -N parallel_example
#$ -pe OpenMP 12
 
# initiallise environment module 
. /etc/profile.d/modules.sh
 
# use Intel compilers (icc,ifort)
# Load R
module load R/3.2.2
module load gcc/4.8.3
module load intel
 
# set number of threads
 
export OMP_NUM_THREADS=$NSLOTS
echo OMP_NUM_THREADS=$OMP_NUM_THREADS

R CMD BATCH my.R my.out

```