# umx_set_optimizer("CSOLNP")
# umx_set_optimizer("NPSOL")
# This is an unreliable mess
mxMatrix(name = "thresh", "Full",
    # values = Mx1Threshold,
    values = cbind(
		seq(-1.9, 1.9, length.out = nthreshNeurot),          
		c(rep(1, nthreshMDD), rep(0, diff)    ),
		seq(-1.9, 1.9, length.out = nthreshNeurot),          
		c(rep(1, nthreshMDD), rep(0, diff)    )
    ),
    free   = c(rep(c(rep(TRUE, nthreshNeurot), rep(TRUE, nthreshMDD), rep(FALSE, diff)), 2)),
    labels = rep(c(paste0("neur", 1:nthreshNeurot), paste0("mddd4l", 1:nthreshMDD), rep(NA, diff)) )
)

# ==========================================================
# = OpenMx Ordinal Data Example: Michael Neale 14 Aug 2010 =
# ==========================================================

# =====================================
# = Step 1: load libraries and helper =
# =====================================
require(OpenMx)
require(MASS)
isIdentified <- function(nVariables, nFactors){
	# If this function returns FALSE then model is not identified, otherwise it is.
	as.logical(1 + sign((nVariables * (nVariables - 1) / 2) -  nVariables * nFactors + nFactors * (nFactors - 1) / 2))
}

# ===================================
# Step 2: set up simulation parameters 
# Note: nVariables>=3, nThresholds>=1, nSubjects>=nVariables*nThresholds (maybe more)
# and model should be identified
# ===================================

nVariables  = 3
nFactors    = 1
nThresholds = 3
nSubjects   = 5000

isIdentified(nVariables, nFactors)

loadings  = matrix(.7, nrow = nVariables, ncol = nFactors)
residuals = 1 - (loadings * loadings)
sigma     = loadings %*% t(loadings) + vec2diag(residuals)
mu        = matrix(0, nrow = nVariables, ncol = 1)

# =============================================
# = Step 3: simulate multivariate normal data =
# =============================================
set.seed(1234)
continuousData <- mvrnorm(n = nSubjects, mu, sigma)

# = Step 3b: chop continuous variables into ordinal data. based on 1st variable, 
# create nThresholds+1 approximately-equal sized categories.
# ========================================================
cutPoints   <- quantile(continuousData[,1], probs = c((1:nThresholds)/(nThresholds+1)))
cutPoints   <- c(-Inf, cutPoints, Inf)
ordinalData <- matrix(0, nrow = nSubjects, ncol = nVariables)
for(i in 1:nVariables) {
	ordinalData[,i] <- cut(continuousData[,i], cutPoints)
}
head(ordinalData)

# Step 5: Make the ordinal variables into mxFactors (R factors that ensure ordered is true, and require the user to set the levels)
ordinalData <- mxFactor(as.data.frame(ordinalData), levels = c(1:(nThresholds + 1)))

# Step 6: name the variables
colNames <- paste0("banana", 1:nVariables)
names(ordinalData) <- colNames

thresholdModel <- mxModel("thresholdModel",
	mxMatrix(name = "L"           , "Full", nVariables, nFactors, values=0.2, free=T, lbound = -.99, ubound=.99),
	mxMatrix(name = "M"           , "Zero", 1         , nVariables),
	mxMatrix(name = "vectorofOnes", "Unit", nVariables, 1),
    mxMatrix(name = "unitLower", "Lower", nThresholds, nThresholds, values = 1,free = F),
	mxMatrix(name="thresholdDeviations", "Full", nrow = nThresholds, ncol = nVariables, values = .2, free = TRUE, 
		lbound = rep( c(-Inf,rep(.01,(nThresholds-1))) , nVariables), dimnames = list(c(), colNames)
	),
	mxAlgebra(name = "E", vectorofOnes - (diag2vec(L %*% t(L)))),
	mxAlgebra(name = "impliedCovs"  , L %*% t(L) + vec2diag(E)),
    mxAlgebra(name="thresholdMatrix", unitLower %*% thresholdDeviations),
    mxExpectationNormal("impliedCovs", means = "M", dimnames = colNames, thresholds = "thresholdMatrix"),
    mxFitFunctionML(),
    mxData(observed = ordinalData, type = 'raw')
)
thresholdModel <- mxRun(thresholdModel)
thresholdModel <- mxRun(thresholdModel)
mxSummary(thresholdModel)

# TODO figure out what Mike is doing with vector of ones
timModel <- mxModel("timModel",
	mxMatrix(name = "L"           , "Full", nVariables, nFactors, values=0.2, free=T, lbound = -.99, ubound=.99),
	mxMatrix(name = "M"           , "Full", 1         , nVariables),
	mxMatrix(name = "vectorofOnes", "Unit", nVariables, 1),
	mxAlgebra(name = "E", vectorofOnes - (diag2vec(L %*% t(L)))),
	mxAlgebra(name = "impliedCovs"  , L %*% t(L) + vec2diag(E)),
	umxThresholdMatrix(ordinalData),
    mxExpectationNormal("impliedCovs", means = "M", dimnames = colNames, thresholds = "thresholdMatrix"),
    mxFitFunctionML(),
    mxData(ordinalData, type = 'raw')
)

# ==============================
# = Easy way to do all ordinal =
# ==============================
require(OpenMx)
# Ordinal Data test, based on poly3dz.mx
# Data: don't make people guess
nameList      = umx_paste_names(c("Neuroticism", "MajorDepression"), "_T", 1:2)
nVar          = length(nameList)
nthreshMDD    = 1
nthreshNeurot = 12	
diff          = (nthreshNeurot - nthreshMDD)
maxThresh     = max(c(nthreshNeurot, nthreshMDD))
twinData      = read.table("~/bin/OpenMx/trunk/models/passing/data/mddndzf.dat", na.string = ".", col.names = nameList)
# TODO: umxFunction that applies mxFactor assuming the full range is contained in the data?
twinData[, c(1, 3)] <- mxFactor(twinData[, c(1, 3)], c(0 : nthreshNeurot))
twinData[, c(2, 4)] <- mxFactor(twinData[, c(2, 4)], c(0 : nthreshMDD))
df = twinData; str(df)
# Define the model
model <- mxModel("bob", 
	umxLabel(mxMatrix(name = "expCov", "Stand", nrow = nVar, ncol = nVar, free = TRUE)),
	# mxEval(round(expCov,3), model)
	#       [,1]   [,2]   [,3]  [,4]
	# [1,] 1.000  0.296  0.127 0.076
	# [2,] 0.296  1.000 -0.001 0.187
	# [3,] 0.127 -0.001  1.000 0.438
	# [4,] 0.076  0.187  0.438 1.000

	# compare to umxHetCor(df, verbose=T)

	mxMatrix(name = "expMean", "Zero" , nrow = 1, ncol = nVar, free = FALSE),
	# t1Neur1 & t2Neur1  : 12 thresholds evenly spaced from -1.9 to 1.9
	# t1mddd4l & t2mddd4l: 1 threshold at 1
	mxMatrix(name = "threshMat", "Full",
            # values = Mx1Threshold,
            values = cbind(
				seq(-1.9, 1.9, length.out = nthreshNeurot),          
				c(rep(1, nthreshMDD), rep(0, diff)    ),
				seq(-1.9, 1.9, length.out = nthreshNeurot),          
				c(rep(1, nthreshMDD), rep(0, diff)    )
            ),
            free   = c(rep(c(rep(TRUE, nthreshNeurot), rep(TRUE, nthreshMDD), rep(FALSE, diff)), 2)),
            labels = rep(c(paste0("neur_th", 1:nthreshNeurot), paste0("mddd4l_th", 1:nthreshMDD), rep(NA, diff)) )
	),
	# Add the objective function, data for observed covariance
	mxExpectationNormal("expCov", means="expMean", dimnames=nameList, thresholds="threshMat"),
	mxFitFunctionML(),
	mxData(df, type = 'raw')
)

# Run the job
model <- mxRun(model)
summary(model)$parameters[,1:6]
round(model$expCov$values,3)

# ===========================
# = Results from classic Mx =
# ===========================

Mx1Threshold <- rbind(
	c(-1.9209, 0.3935, -1.9209, 0.3935),
	c(-0.5880, 0    , -0.5880, 0    ),
	c(-0.0612, 0    , -0.0612, 0    ),
	c( 0.3239, 0    ,  0.3239, 0    ),
	c( 0.6936, 0    ,  0.6936, 0    ),
	c( 0.8856, 0    ,  0.8856, 0    ),
	c( 1.0995, 0    ,  1.0995, 0    ),
	c( 1.3637, 0    ,  1.3637, 0    ),
	c( 1.5031, 0    ,  1.5031, 0    ),
	c( 1.7498, 0    ,  1.7498, 0    ),
	c( 2.0733, 0    ,  2.0733, 0    ),
	c( 2.3768, 0    ,  2.3768, 0    )
)

Mx1R <- rbind(
    c(1.0000,  0.2955,  0.1268, 0.0760),
    c(0.2955,  1.0000, -0.0011, 0.1869),
    c(0.1268, -0.0011,  1.0000, 0.4377),
    c(0.0760,  0.1869,  0.4377, 1.0000)
)

omxCheckCloseEnough(mxEval(threshMat, model)[,1], Mx1Threshold[,1], 0.01)
omxCheckCloseEnough(mxEval(threshMat, model)[1,2], Mx1Threshold[1,2], 0.01)
omxCheckCloseEnough(mxEval(expCov, model), Mx1R, 0.01)
omxCheckCloseEnough(model$output$Minus2LogLikelihood, 4081.48, 0.02)


m1 <- mxModel("mine",
	mxMatrix(name = "expCov" , "Stand", nrow = nVar, ncol = nVar, free = TRUE, dimnames = list(names(df),names(df))),
	mxMatrix(name = "expMean", "Zero" , nrow = 1   , ncol = nVar, free = FALSE, dimnames = list(NULL, names(df))),
	umxThresholdMatrix(df, suffixes = c("_T1", "_T2")),
	mxExpectationNormal("expCov", "expMean", thresholds = "threshMat"),
	mxFitFunctionML(),
	mxData(df, type = 'raw')
)
m1 = mxRun(m1)
summary(m1)
round(m1$expCov$values,3)
mxCompare(model, m1)

m1 <- mxModel("umxOrdinalObjective", 
	mxMatrix(name = "expCov", "Stand", nrow = nVar, ncol = nVar, free = TRUE),
	mxMatrix(name = "expMean", "Zero" , nrow = 1   , ncol = nVar),
	umxOrdinalObjective(df, suffixes = c("_T1", "_T2")),
	mxData(df, type = 'raw')
)
m1 = mxRun(m1)
mxCompare(model,m1)

# Scale doesn't matter
x  = mxMatrix(name = "expCov" , "Symm", nrow = nVar, ncol = nVar, free = TRUE)
# fix the diag @ pi
diag(x$free) = FALSE
diag(x$values) = pi
m2 <- mxModel(m1, name="scale not matter", x,
	mxMatrix(name = "expMean", "Full", nrow = 1, ncol = nVar, free = FALSE, values = pi)
)
m2 = mxRun(m2)
mxCompare(m1,m2)
summary(m2)
round(cov2cor(m1$expCov$values),3)
#         Neuroticism_T1 MajorDepression_T1 Neuroticism_T2 MajorDepression_T2
# N_T1    1.000              
# DepT1   0.295              1.000
# N_T2    0.127             -0.001          1.000
# Dep_T2  0.076              0.187          0.438              1.000

require(OpenMx); library(umx)
data(twinData)
twinData$zyg = factor(twinData$zyg, levels = 1:5, labels = c("MZFF", "MZMM", "DZFF", "DZMM", "DZOS"))
# ==============================
# = MIxed example: Binary data =
# ==============================
# Cut bmi to form category of 20% obese subjects
obesityLevels = c('normal', 'obese')
ordDVs = c("obese1", "obese2")
selDVs = c("wt1", "obese1", "wt2", "obese2")
cutPoints <- quantile(twinData[, "bmi1"], probs = .2, na.rm = TRUE)
twinData$obese1 <- cut(twinData$bmi1, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
twinData$obese2 <- cut(twinData$bmi2, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
twinData[, ordDVs] <- mxFactor(twinData[, ordDVs], levels = obesityLevels)
mzData <- subset(twinData, zyg == "MZFF", selDVs)

varianceStarts = rep(1, nVar)
varianceStarts[!umx_is_ordinal(mzData)] = diag(var(mzData[,!umx_is_ordinal(mzData)], use="complete"))
expCov  = mxMatrix(name = "expCov", "Symm", nrow = nVar, ncol = nVar, values = .3, free = TRUE, dimnames = list(selDVs, selDVs))
expMean = mxMatrix(name = "expMean", "Full", nrow = 1, ncol = nVar, free = !umx_is_ordinal(mzData), values = 0, dimnames = list(NULL, selDVs))
diag(expCov$free) = !umx_is_ordinal(mzData)
diag(expCov$values) = varianceStarts
expMean$values[!umx_is_ordinal(mzData)] = colMeans(mzData[,!umx_is_ordinal(mzData)], na.rm=T)

m1 <- mxModel("mixBin_Cont", expCov, expMean,
	umxThresholdMatrix(mzData, suffixes = 1:2), # returns threshMat
	mxExpectationNormal("expCov", "expMean", thresholds = "threshMat"),
	mxFitFunctionML(),
	mxData(mzData, type = 'raw')
)
umx_set_optimizer("CSOLNP")
m1 = mxRun(m1)
# summary(m1)
round(m1$expCov$values, 3)
round(cov2cor(m1$expCov$values), 3)

# ======================================
# = Ordinal example (>2 categories)    =
# ======================================

# Cut to form three categories of weight
ordDVs = c("obese1", "obese2")
selDVs = c("wt1", "obese1", "wt2", "obese2")
obesityLevels = c('normal', 'overweight', 'obese')
cutPoints <- quantile(twinData[, "bmi1"], probs = c(.4, .7), na.rm = TRUE)
twinData$obese1 <- cut(twinData$bmi1, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
twinData$obese2 <- cut(twinData$bmi2, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
twinData[, ordDVs] <- mxFactor(twinData[, ordDVs], levels = obesityLevels)
mzData <- subset(twinData, zyg == "MZFF", selDVs)

varianceStarts = rep(1, nVar)
varianceStarts[!umx_is_ordinal(mzData)] = diag(var(mzData[,!umx_is_ordinal(mzData)], use="complete"))
expCov  = mxMatrix(name = "expCov", "Symm", nrow = nVar, ncol = nVar, values = .3, free = TRUE, dimnames = list(selDVs, selDVs))
expMean = mxMatrix(name = "expMean", "Full", nrow = 1, ncol = nVar, free = TRUE, values = 0, dimnames = list(NULL, selDVs))
diag(expCov$values) = varianceStarts
expMean$values[!umx_is_ordinal(mzData)] = colMeans(mzData[,!umx_is_ordinal(mzData)], na.rm=T)

m2 <- mxModel("mixOrd_Cont", expCov, expMean,
	umxThresholdMatrix(mzData, suffixes = 1:2), # returns threshMat
	mxExpectationNormal("expCov", "expMean", thresholds = "threshMat"),
	mxFitFunctionML(),
	mxData(mzData, type = 'raw')
)

m2 = mxRun(m2)
summary(m2)
round(m2$expCov$values, 3)
round(cov2cor(m2$expCov$values), 3)

sort.data.frame <- function(x, decreasing = FALSE, by = 1, ... ){
  f <- function(...) {
	  order(...,decreasing=decreasing)
  }
  i <- do.call(f, x[by])
  x[i, , drop = FALSE]
}
It sorts on the first column by default, but you may use any vector of valid column indices. Here are some examples.

sort(iris, by="Sepal.Length")
sort(iris, by=c("Species","Sepal.Length"))
sort(iris, by=1:2)
sort(iris, by="Sepal.Length",decreasing=TRUE)


# ==============================
# = ACE not running by default =
# ==============================
devtools::document("~/bin/umx"); devtools::install("~/bin/umx");
devtools::document("~/bin/umx.twin"); devtools::install("~/bin/umx.twin");

data(twinData)
twinData$zyg = factor(twinData$zyg, levels = 1:5, labels = c("MZFF", "MZMM", "DZFF", "DZMM", "DZOS"))
ordDVs = c("obese1", "obese2")
obesityLevels = c('normal', 'overweight', 'obese')
cutPoints <- quantile(twinData[, "bmi1"], probs = c(.5, .2), na.rm = TRUE)
twinData$obese1 <- cut(twinData$bmi1, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels)
twinData$obese2 <- cut(twinData$bmi2, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels)
twinData[, ordDVs] <- mxFactor(twinData[, ordDVs], levels = obesityLevels)
selDVs = c("wt", "obese")
mzData <- subset(twinData, zyg == "MZFF", umx_paste_names(selDVs, "", 1:2))
dzData <- subset(twinData, zyg == "DZFF", umx_paste_names(selDVs, "", 1:2))
str(mzData)
m1 = umxACE(selDVs = selDVs, dzData = dzData, mzData = mzData, suffix = '')
m1 = mxRun(m1)
umxSummaryACE(m1)
 
# ========================
# = 1. Run unsafe = TRUE =
# ========================
m1 = mxRun(m1, unsafe=T); umxSummaryACE(m1)

# ==========================
# = 2. lower off diagonals =
# ==========================
m1$top$expCovMZ

m1$top$a$values
#          [,1]      [,2]
# [1,] 0.5364019 0.0000000
# [2,] 0.5886977 0.6318429

m1$top$a$values[2,1] = .3
m1$top$c$values[2,1] = .0
m1$top$e$values[2,1] = .1
m1 = mxRun(m1, unsafe=T); umxSummaryACE(m1)
# -2 × log(Likelihood)
# 'log Lik.' 61123.46 (df=11)
# Standardized solution
#           a1    a2    c1    c2    e1 e2
# wt1     0.70        0.01        0.71
# obese1 -0.76 -0.03 -0.11 -0.03 -0.64  .

eigen(m1$top$a$values)$values
eigen(m1$top$c$values)$values
eigen(m1$top$e$values)$values
cov(m1$MZ$data)
a = e = t(chol(cov(m1$MZ$data@observed[c(1,3)], use="pair")))/3
c = t(chol(cov(m1$MZ$data@observed[c(1,3)], use="pair")))/4


m1 = omxSetParameters(m1, "a_r2c1", free=F, values=0); m1 = mxRun(m1, unsafe=T)

# =======================
# = 3. move thresholds? =
# =======================
m1$top$threshMat
m1 = omxSetParameters(m1, "obese_thresh1", free=F, values=0); m1 = mxRun(m1, unsafe=T)
