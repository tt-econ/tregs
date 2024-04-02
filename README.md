# README

<p align="center">
  <img src="/misc/tregs_stata.png" width="420">
</p>

## Description

Linear regression with transformed dependent variable

This Stata package runs regressions with log or power transformations of the dependent variable on a list of covariates and computes semi-elasticities and elasticities for a set of specified covariates.

The predicted value of the untransformed dependent variable can be calculated at specified values of the covariates.

The transformations supported by this package (log and power) are the only choices that result in estimates that do not depend on the measurement units (scaling) of the data, characterized by Thakral and Tô (2024). For an illustration of the problems that arise when using other popular transformations such as log(y+1) or the inverse hyperbolic sine, see [wreckitreg](https://github.com/tt-econ/wreckitreg).

## Requirements

- Stata 11 and above

## Installation

From Stata:

```
   net install tregs, from("https://raw.githubusercontent.com/tt-econ/tregs/main/pkg")
```

## Example

In Stata, after installation:

```
. sysuse sp500, clear
(S&P 500)

. tsset date

Time variable: date, 02jan2001 to 31dec2001, but with gaps
        Delta: 1 day

. tregs change L.high L.low, xvar(volume) log mostlinear reset
Warning: You specified variables in xvar() that are not included as covariates. All variables in xvar() have been added as covariates in all regressions
> .
Warning: The dependent variable change contain values that are not strictly positive. The log specification will only take into account strictly positiv
> e values of change.
Computing the power with the highest RESET specification test p-value...
Power with the highest p-value in the RESET specification test: 1/9
Processing specification: y^1
  - Computing semi-elasticity and elasticity with respect to volume
Processing specification: y^(1/3)
  - Computing semi-elasticity and elasticity with respect to volume
Processing specification: y^(1/5)
  - Computing semi-elasticity and elasticity with respect to volume
Processing specification: log(y)
Note: 99 number of observations dropped after the transformation.
  - Computing semi-elasticity and elasticity with respect to volume
Processing specification: y^(1/9)
  - Computing semi-elasticity and elasticity with respect to volume

Regression Results, Dep. Var: Closing price change
---------------------------------------------------------------------------------------------------------
                                   (1)             (2)             (3)             (4)             (5)
                                   y^1         y^(1/3)         y^(1/5)          log(y)         y^(1/9)
---------------------------------------------------------------------------------------------------------
L.High price                    -0.105         -0.0152         -0.0110          0.0103        -0.00909
                               (0.140)        (0.0189)        (0.0132)       (0.00918)        (0.0105)

L.Low price                     0.0936          0.0125         0.00905         -0.0101         0.00751
                               (0.139)        (0.0189)        (0.0133)       (0.00908)        (0.0106)

Volume (thousands)            0.000814       0.0000404       0.0000195        0.000135***    0.0000116
                            (0.000784)     (0.0000907)     (0.0000623)     (0.0000484)     (0.0000492)
---------------------------------------------------------------------------------------------------------
eydx: Volume (thousands)      -0.00222        -0.00174        -0.00200        0.000135        -0.00266
eyex: Volume (thousands)        -27.35          -21.44          -24.61           1.667          -32.83
Predicted y: At means           -0.369          -0.450          -0.355           11.31           0.279
RESET Test p                 0.0000854          0.0189           0.119         0.00804           0.157
Observations                       192             192             192              93             192
---------------------------------------------------------------------------------------------------------
Standard errors in parentheses
* p<0.10, ** p<0.05, *** p<0.01
```

See the help file for more: In Stata, type `help tregs` after installation.

Also see the [package's page](https://tt-econ.github.io/tregs) for more detailed examples and how to access returned results.

## References

The package implements the recommendations of the following paper, which shows that log and power are the only transformations for OLS that result in estimates that do not depend on the scaling of the data:

- ["When Are Estimates Independent of Measurement Units?" (Thakral and Tô 2024)](https://linh.to/files/papers/transformations.pdf)

Formulas for the semi-elasticities and elasticities can be found in the paper above, while formulas for predicted values can be found in the paper below, which establishes analogous results for generalized linear models:

- "Scale Equivariance in Regressions" (Thakral and Tô 2024)

## Contact

- [Linh T. Tô](https://linh.to) (linhto@bu.edu)
- [Neil Thakral](https://neilthakral.github.io) (neil_thakral@brown.edu)

Michael Briskin greatly contributed to the package.


&nbsp;

Ⓒ 2023–2024 Linh T. Tô and Neil Thakral
