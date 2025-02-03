{smcl}
{* *! version 2.1.0 1feb2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help wreckitreg" "help wreckitreg"}{...}
{vieweralsosee "Help reghdfe" "help reghdfe"}{...}
{vieweralsosee "Help regress" "help regress"}{...}
{vieweralsosee "Help margins" "help margins"}{...}
{viewerjumpto "Syntax" "tregs##syntax"}{...}
{viewerjumpto "Description" "tregs##description"}{...}
{viewerjumpto "Options" "tregs##options"}{...}
{viewerjumpto "Examples" "tregs##examples"}{...}
{viewerjumpto "References" "tregs##references"}{...}
{viewerjumpto "Author" "tregs##contact"}{...}

{title:Title}

{phang}
{cmd:tregs} {hline 2} Linear regression with transformed dependent variable

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:tregs}
{depvar} [{indepvars}]
{ifin} {weight},
{bf:xvar(varlist)}
[{help tregs##options:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Elasticities and Predicted Values}

{synopt:{opt xvar(varlist)}}  compute semi-elasticity and elasticity estimates for these independent variables (required)

{synopt:{opt at(string)}}  compute semi-elasticity, elasticity, and predicted value at specific covariate values instead of at means

{syntab:Specifications}

{synopt:{opt pow:ers(string)}}  specify powers for transforming {it:depvar}

{synopt:{opt log}}  add a specification with log of {it:depvar}; applied only to strictly positive observations

{synopt:{opt a:bsorb(string)}}  absorb fixed effects in {help reghdfe}

{synopt:{opt noa:bsorb}}  use {help reghdfe} with no fixed effects instead of {help regress}

{synopt:{opt regopts(string)}}  include any regression options valid with {help regress} or {help reghdfe}

{syntab:Specification Tests}

{synopt:{opt andrew:stest}} compute the p-value from the Andrews 1971 linear model specification test

{synopt:{opt reset:test}} compute the p-value from Ramsey Regression Equation Specification Error Test (RESET)

{synopt:{opt swilk:test}} compute the p-value from Shapiro-Wilk test for normality of the error term; see {help swilk}

{synopt:{opt mostlinear}}  add a power (between 0 and 1) to the list of {helpb tregs##powers:powers} that maximizes the p-value of the RESET test


{syntab:Output Format}

{synopt:{opt reg_pre:fix(string)}}  specify shared prefix to different stored regression estimates; default is "reg_"

{synopt:{opt noisily}} display all output from regression specifications and calculations

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{cmd:tregs} runs regressions using {help reghdfe} or {help regress} with log or power transformations of {it:depvar} on a list of covariates and computes semi-elasticities and elasticities for the covariates specified in {helpb tregs##xvar:xvar}.

{pstd}
The predicted value of the untransformed {it:depvar} can be calculated at specified values of {it:indepvars} using the syntax of {help margins##atspec}.

{pstd}
The transformations supported by this package (log and power) are the only choices that result in estimates that do not depend on the measurement units (scaling) of the data, characterized by Thakral and Tô (2024). For an illustration of the problems that arise when using other popular transformations such as log(y+1) or the inverse hyperbolic sine, see {browse "https://github.com/tt-econ/wreckitreg":wreckitreg}.

{marker options}{...}
{title:Options}

{dlgtab:Elasticities and Predicted Values}

{marker xvar}{...}
{phang}
{opt xvar(varlist)} computes semi-elasticity and elasticity estimates of {it:depvar} with respect to these variables. Any variable included in {opt xvar(varlist)} but not specified in {it:indepvars} will be added as a covariate in all regressions. If you want the regressions to treat any particular X variable as a binary variable, then you can use factor variable syntax when specifying the corresponding variable in the {it:indepvars} list in the command. By default, the semi-elasticity and elasticity estimates are computed at the means of the covariates. To specify other values, see {help tregs##at:at}. In the output, semi-elasticities are denoted as {bf:eydx} and elasticities are denoted as {bf:eyex}, following the convention in {help margins}.

{marker at}{...}
{phang}
{opt at(string)} provides the option to compute semi-elasticity, elasticity, and predicted value of the untransformed {it:depvar} at specified values of {it:indepvars}. When this option is not specified, or when {bf:atmeans} is specified, these estimates are computed at the means of the independent variables. Use the {help margins##atspec} syntax to specify values for covariates at which to compute the estimates. The predicted value is obtained from the transformed regression and transformed back into the original units of the dependent variable using the smearing estimate of Duan (1983).

{dlgtab:Specifications}

{marker powers}{...}
{phang}
{opt pow:ers(string)} specifies the list of power transformations of {it:depvar}. The powers are decimal numbers or rationals of the form {it:a/b}. The default is (1, 1/2, 1/3, 1/4, 1/5), or (1, 1/3, 1/5) when {it:depvar} has both strictly positive and negative values. Negative powers are allowed but apply only if {it:depvar} has only strictly positive or only strictly negative values. For {it:depvar} with both strictly positive and strictly negative values, the powers should be input as fractions.

{phang}
{opt log} adds the logarithm of {it:depvar} as a transformation specification. Observations with weakly negative {it:depvar} will not be used in this specification.

{phang}
{opt a:bsorb(string)} passes fixed effects to the {help reghdfe##absvar:absorb} option in {help reghdfe}. When this is specified, {help reghdfe} will be used instead of {help regress}.

{phang}
{opt noa:bsorb} allows the use of {help reghdfe} even when there are no fixed effects, for example, to leverage multi-way clustering. One cannot specify both {opt a:bsorb(string)} and {opt noa:bsorb} at the same time.

{phang}
{opt regopts(string)} allows options to be passed to {help reghdfe} (when either {opt a:bsorb(string)} or {opt noa:bsorb} is specified) or to {help regress}. Note that if clustering is not specified, {bf:vce(robust)} will be added by default.

{dlgtab:Specification Tests}

{phang}
{opt andrew:stest} conducts the Andrews (1971) linear model specification test for each specification and prints the p-value associated with the null hypothesis of a correctly specified linear model. This test requires that the predicted values of the transformed {it:depvar} are always strictly positive.

{phang}
{opt reset:test} conducts the Ramsey (1969) Regression Equation Specification Error Test (RESET) for each specification and prints the p-value associated with the null hypothesis of a correctly specified linear model. Powers of the fitted values up to 4 degrees are used.

{phang}
{opt swilk:test} prints the p-value from Shapiro-Wilk test of the null hypothesis is that the distribution of the residuals is normal. See {help swilk} for more information (for example, the number of observations needs to be between 4 and 2000).

{phang}
{opt mostlinear} runs a grid search of powers 1/99, 2/99, up to 99/99 to find the one that will maximize the p-value of the RESET test. This set of powers accommodates data containing both positive and negative values. It then adds this power to the list of {opt pow:ers(string)}, if it is not already in the list, before running all specifications.

{dlgtab:Output Format}

{phang}
{opt reg_pre:fix(string)} specifies prefix common to different stored regression estimates; default is "reg_". The full name of each stored estimate begins with this prefix and follows with the name of the power or log specification. For example, regression results with the power 2 are stored as reg_2, regression results with the power 1/2 are stored as reg_1_2, regression results with the power 0.3 are stored as reg_0dot3, and regression results with log are stored as reg_log.

{phang}
{opt noisily}  displays all output from regression specifications and elasticity calculations; default is to suppress these intermediate steps. This is useful mainly for debugging.

{marker examples}{...}
{title:Examples}

{stata sysuse sp500, clear}
{stata tsset date}
{stata tregs change L.high L.low volume, pow(1 1/2 1/3 1/4 1/5 1/6 1/7) xvar(volume) log mostlinear reset}

{stata sysuse nlsw88, clear}
{stata tregs wage i.race, absorb(ttl_exp#age) xvar(grade) at(grade = 12) log reset regopts(vce(cluster age)) mostlinear}


{marker references}{...}
{title:References}

{p 0 0 2}
The package implements the recommendations of the following paper, which shows that log and power are the only transformations for OLS that result in estimates that do not depend on the scaling of the data:

{phang}
Neil Thakral and Linh T. Tô. "When Are Estimates Independent of Measurement Units?".
{it:Working paper, 2025.}
{browse "https://linh.to/files/papers/transformations.pdf":[link]}
{p_end}

{p 0 0 2}
Formulas for the semi-elasticities and elasticities can be found in the paper above, while formulas for predicted values can be found in the paper below, which establishes analogous results for generalized linear models:

{phang}
Neil Thakral and Linh T. Tô. "Scale Equivariance in Regressions".
{it:Working paper, 2025.}
{p_end}

See also:

{phang}
David Andrews. "A Note on the Selection of Data Transformations".
{it:Biometrika, 1971.}
{p_end}

{phang}
Naihua Duan. "Smearing Estimate: A Nonparametric Retransformation Method".
{it:Journal of the American Statistical Association, 1983.}
{p_end}

{phang}
James Ramsey. "Tests for Specification Errors in Classical Linear Least Squares Regression Analysis".
{it:Journal of the Royal Statistical Society, Series B, 1969.}
{p_end}

{marker contact}{...}
{title:Author}
{p}

Linh Tô, Boston University
Meil Thakral, Brown University
Michael Briskin, Boston University

Email {browse "mailto:linhto@bu.edu":linhto@bu.edu}

Also see {browse "https://tt-econ.github.io/tregs":the package website}.
