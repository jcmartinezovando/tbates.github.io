---
layout: post
title: "Confidence on standardized parameters"

comments: true
categories: advanced
---

This page is not yet finished!

This Page will discuss getting CIs on standardized parameters. Often, unstandardized variables are valuable: They give us a read-out of effects in the natural units of the variables in the model – change in miles per gallon for 1kg of extra vehicle weight, instead of change in standardized miles per gallon per scaled unit of weight.

However, especially in social science, readers are used to standardized effects. In addition, readers might want an idea of the relative size of an effect, and standardized parameters convey this.

In OpenMx there are three ways you can get CIs on standardized values.

1. Using SEs from mxSummary (for RAM models)
2. Re-running the model on standardized data
3. Adding mxAlgebras to compute the standardized effect, along with mxCIs on these.

### 1. Using SEs

Method 1 is easiest, and this is what `umxSummary` does for you.

Given a RAM model, `umxSummary` will report both the raw and standardized parameter estimates, and also the SE and standardized SE. You can calculate 95% confidence intervals around the standardized parameter values using the formula `std estimate - (1.96 × std.SE)` and `std estimate + (1.96 × std.SE)`. If you run umxSummary, this is what happens under the hood.

PS: If you haven't tried `umxAPA` have a look now: it can take many objects, and turn them into APA-style report format. For instance, data, lm results, and also effects/SE pairings.


### 2.  Using scaled data

A second method is to `scale()` your data (the easiest way is with `umxScale`, which handles skipping over binary and factor variables properly), and run the model on this z-scored data. All estimates are automatically in standardized terms. You can also add mxCI calls to the model to get profile-based estimates of confidence rather than extrapolate from the SEs.

### 2.  Adding algebras which compute the scaled value and calling mxCI

If you are an advanced user, you might add `mxAlgebra` calls which compute the standardized parameters (umxACE does this under-the-hood, for instance).

To get CIs around these algebras, you can either call mxSE(), giving it the model and the algebra you wish to estimate CIs for, or add `mxCI` calls to model requesting CIs for these algebras. OpenMx will vary the underlying parameters to drive the model fit to the edge of the requested confidence limit for each of the CIs you request.

*nb*: For large, complex, raw-data or ordinal models, profile CIs can be very time-consuming. 

```r
library(umx);
data(myFADataRaw, package="OpenMx")
manifests = paste0("x",1:6)
myFADataRaw = myFADataRaw[, manifests]
a1 = umxRAM("m1",
	umxPath(from = "g", to = manifests),
	umxPath(var  = manifests),
	umxPath(var  = "g", fixedAt = 1),
	data = mxData(cov(myFADataRaw, use = "complete"), type = "cov", numObs = nrow(myFADataRaw))
)
a1 = umxRun(a1); umxSummary(a1)
```

Now, we can add a set of standardization algebras

```r    
a1 = umx_add_std(a1, addCIs = TRUE)
a1 = umxRun(a1); umxSummary(a1)
```

If we set `intervals = TRUE` in `mxRun()` then we get the requested CIs. This is needed because CIs take time, so they are off by default.

```r    
a1 = umxRun(a1, intervals = TRUE);
a1@output$confidenceIntervals

```
### umxSummary can format all this nicely for you.

Not yet, but hopefully soon.

```r
umxSummary(a1)
# TODO modify this to report CIs
# 1. Incorporate estimate in the CI table
# 2. Use labels instead of bracket addressing from algebra
```

### Hard way to see how we do it inside

```r
freeS = umx_make_bracket_addresses(a2@matrices$A, free= TRUE, newName="stdA")
# a3 = mxModel(a2, mxCI("stdS"))
a3 = mxModel(a2, mxCI(freeS))
a3 = mxRun(a3, intervals = TRUE); umxSummary(a3)
umx_report_time(a3)
summary(a3)$CI

```