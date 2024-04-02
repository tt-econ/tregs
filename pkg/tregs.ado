*! version 2.0.0 31mar2024

program define tregs, sortpreserve eclass
version 11
    syntax varlist(ts fv) [if] [in] [aw fw iw pw], xvar(string) [log xvar_at(string) regopts(string) NOISILY REG_PREfix(string) POWers(string) Absorb(string) NOAbsorb PREDicted_y(string) RESETtest SWILKtest ANDREWstest mostlinear]

    capture : which estout
    if (_rc) {
        display as result in smcl `"Please install package {it:estout} from SSC in order to run this command;"' _newline ///
            `"you can do so by clicking this link: {stata "ssc install estout":auto-install estout}"'
        exit 199
    }

    local y `: word 1 of `varlist''
    local indepvars: list varlist - y
    local count_xvar: word count `xvar'
    local count_at: word count `xvar_at'
    local count_powers: word count `powers'

    if (`count_at' != `count_xvar') & (`count_at' > 0) {
        di as error "The number of values in {it:xvar_at} must match the number of covariates in {it:xvar}."
        exit 198
    }

    * Check if xvar is subset of covariates
    * If not, issue a warning and add xvar to the set of covariates
    local missingx
    foreach x in `xvar' {
        if !strpos("`indepvars'","`x'") {
            local missingx `missingx' `x'
        }
    }

    if "`missingx'"!="" {
        di as result in smcl "Warning: You specified variables in {it:xvar()} that are not included as covariates. All variables in {it:xvar()} have been added as covariates in all regressions."
        local indepvars `indepvars' `missingx'
    }

    fvexpand `indepvars'
    local cnames `r(varlist)'

    if "`noisily'"!="" {
        local quietly_noisily noisily
    }
    else {
        local quietly_noisily quietly
    }

    * reg/reghdfe options
    if "`absorb'"!="" & "`noabsorb'"!="" {
            display as error in smcl `"Options {it:absorb} and {it:noabsorb} cannot both be specified."'
            exit 199
    }

    if "`absorb'" != "" | "`noabsorb'" != "" {
        capture : which reghdfe
        if (_rc) {
            display as result in smcl `"Please install package {it:reghdfe} from SSC in order to run this command;"' _newline ///
                `"you can do so by clicking this link: {stata "ssc install reghdfe":auto-install reghdfe}"'
            exit 199
        }
        local reg_command reghdfe
        if "`noabsorb'" == "" {
            local absorb_option absorb(`absorb')
        }
        else {
            local absorb_option noabsorb
        }
    }
    else {
        local reg_command reg
    }
    // robust SE by default
    if strpos("`regopts'", "vce") == 0 {
        local regopts `regopts' vce(robust)
    }
    // need resid
    if "`reg_command'" == "reghdfe" & strpos("`regopts'", "res") == 0 {
        local regopts `regopts' resid
    }
    // no-resid regopts version
    local count_regopts: word count `regopts'
    forval i = 1/`count_regopts' {
        local opt: word `i' of `regopts'
        if (strpos("`opt'", "res") > 0) {
            local regopts_nores = subinstr("`regopts'", "`opt'", "", 1)
        }
    }

    marksample touse

    * Check if y has negative values
    qui count if `touse' & `y'<0 & !mi(`y')
    local nneg = r(N)

    qui count if `touse' & `y'==0 & !mi(`y')
    local nzero = r(N)

    qui count if `touse' & `y'>0 & !mi(`y')
    local npos = r(N)

    if (`nneg' > 0 | `nzero' > 0) & ("`log'" != "") {
        di as result in smcl "Warning: The dependent variable {it:`y'} contain values that are not strictly positive. The log specification will only take into account strictly positive values of {it:`y'}."
    }

    if "`powers'"!="" {
        local specnum 0
        local speclist

        foreach spec in `powers' {
            local val = `spec'
            capture confirm number `val'
            if (_rc != 0) {
                di as error "Invalid power inputs. Each word in the list must correspond to a real number or a rational of the form a/b."
                exit 198
            }

            // Simplify fractions
            local slash_pos = strpos("`spec'", "/")
            if (`slash_pos' > 0) {
                simplify_fraction, frac(`spec')
                local spec = e(simplified_frac)
                local denominator = e(denominator)
            }

            local toadd 1
            if ((`spec') < 0) {
                if ((`nzero' > 0) | (`nneg' > 0 & `npos' > 0)) {
                    local toadd 0
                    di as result in smcl "Warning: Power {bf:`spec'} is negative: This is invalid when the dependent variable {it:`y'} has zero-valued data or a mix of strictly positive and negative data. {bf:This power will be removed from the list.}"
                }
            }
            else {
                if (`nneg' > 0 & `npos' > 0) {
                    if (`slash_pos' == 0 & `val' != int(`val')) {
                        local toadd 0
                        di as result in smcl "Warning: Power {bf:`spec'} is not expressed as a fraction (a/b format) and the dependent variable {it:`y'} has both positive and negative values. {bf:This power will be removed from the list.}"
                    }
                    else if (`val' == int(`val')) {
                        if (mod(int(`val'), 2) != 1) {
                            local toadd 0
                            di as result in smcl "Warning: Power {bf:`spec'} is even and the dependent variable {it:`y'} has both positive and negative values. {bf:This power will be removed from the list.}"
                        }
                    }
                    else {
                        if (mod(`denominator', 2) != 1) {
                            local toadd 0
                            di as result in smcl "Warning: Simplied power {bf:`spec'} has an even denominator and the dependent variable {it:`y'} has both positive and negative values. {bf:This power will be removed from the list.}"
                        }
                    }
                }
            }
            if (`toadd' == 1) {
                local specnum = `specnum' + 1
                local speclist `speclist' `spec'
            }
        }
    }

    if (`nneg' > 0 & `npos' > 0) {
        if "`speclist'" == "" {
            local speclist 1 1/3 1/5
            local specnum 3
        }
    }
    else {
        if "`speclist'" == "" {
            local speclist 1 1/2 1/3 1/4 1/5
            local specnum 5
        }
    }

    if "`log'" != "" {
        local speclist `speclist' log
        local specnum = `specnum' + 1
    }

    if "`mostlinear'" != "" {
        local weightopts `weight'`exp'
        local if_opts `if'
        local in_opts `in'

        disp as text "Computing the power with the highest RESET specification test p-value..."

        * Call the mata function
        mata: mata clear
        mata: find_max_pvalue("`y'", "`cnames'","`regopts_nores'","`weightopts'","`if_opts'","`in_opts'","`absorb_option'")

        local mostlinear_k `mostlinear_k_bounded'

        simplify_fraction, frac(`mostlinear_k'/99)
        local mostlinear_spec = e(simplified_frac)

        di as result "Power with the highest p-value in the RESET specification test: `mostlinear_spec'"

        local specnum = `specnum' + 1
        local speclist `speclist' `mostlinear_spec'

    }

    est clear
    eststo clear

    if "`reg_prefix'" == "" {
        local reg_pre reg_
    }
    else {
        local reg_pre `reg_prefix'
    }

    fvexpand `xvar'
    local xvar_fv `r(varlist)'

    // Matrix for semi-elasticity, elasticity, and predicted value of y
    matrix Untransformed = J(2 * `count_xvar' + 1, `specnum', .)
    local rownames "X"
    local colnames "X"

    foreach spec in `speclist' {
        if lower("`spec'") == "log" {
            local col `""log(y)""'
        }
        else {
            if strpos("`spec'", "/") > 0 {
                local col `""y^(`spec')""'
            }
            else {
                local col `""y^`spec'""'
            }
        }
        local colnames `colnames' `col'

    }
    local colnames = substr(`""`colnames'"', 3, .)

    foreach t in "Semi-elasticity" "Elasticity" {
        foreach x of varlist `xvar_fv' {
            local row `""`t': `x'""'
            local rownames `rownames' `row'
        }
    }
    if "`predicted_y'" == "" {
        local predy_lab "Predicted y: At means"
    }
    else {
        local predy_lab "Predicted y: At specified"
    }
    local rownames `rownames' `"predy_lab"'
    local rownames = substr(`""`rownames'"', 3, .)

    mat rownames Untransformed = `rownames'
    mat colnames Untransformed = `colnames'

    local scalars_tregs "X"
    * Access variable labels and means
    foreach x of varlist `xvar_fv' {
        if strpos("`x'", ".") > 0 {
            local xx: subinstr local x "." "_", all
        }
        else {
            local xx `x'
        }

        capture local lab_`xx': variable label `x'
        if "`lab_`xx''" == "" {
            local lab_`xx' `x'
        }

        quietly sum `x', meanonly
        local mean_`xx' = r(mean)
    }

    qui count if `touse' & !mi(`y')
    local nobs = r(N)
    `quietly_noisily' {
        local ispec = 0
        foreach spec in `speclist' {
            local ispec = `ispec'+1
            local specname: subinstr local spec "/" "_", all
            local specname: subinstr local specname "-" "neg", all
            local specname: subinstr local specname "." "dot", all
            local tyname: word `ispec' of `colnames'

            if ("`mark_`specname''" == "1") {
                noisily disp as text "Skipping repeated specification: `tyname'"
            }
            else {
                local mark_`specname' 1

                noisily disp as text "Processing specification: `tyname'"

                // transformed y variable
                tempvar ty_`specname'

                if (lower("`spec'") != "log") {
                    // for a negative power, the transformation is multiplied by -1 to become increasing
                    // also need to account for negative y values
                    gen `ty_`specname'' = ( (abs(`y'))^(`spec') * (2*((`spec') > 0) - 1) ) * ( 2 * (`y' > 0) - 1 )
                }
                else {
                    gen `ty_`specname'' = log(`y')
                }
                count if `touse' & !mi(`ty_`specname'')
                local tnobs = r(N)
                if `tnobs' < `nobs' {
                    local dropped = `nobs' - `tnobs'
                    noisily disp as result in smcl "Note: `dropped' number of observations dropped after the transformation."
                }

                local regstore "eststo `reg_pre'`specname':"

                * Run regression
                `regstore' `reg_command' `ty_`specname'' `cnames' `if' `in' [`weight'`exp'], `regopts' `absorb_option'
                qui estimates store `reg_pre'`specname'

                tempvar resid
                predict double `resid' `if' `in', residuals

                * Estimate semi-elasticity and save results

                margins `if' `in', atmeans predict() nose
                local ty_`specname'_atmeans = r(b)[1, 1]

                local ix 0
                foreach x of varlist `xvar_fv' {
                    if strpos("`x'", ".") > 0 {
                        local xx: subinstr local x "." "_", all
                    }
                    else {
                        local xx `x'
                    }

                    noisily disp as text "  - Computing semi-elasticity and elasticity with respect to `x'"

                    local ix = `ix' + 1

                    local beta = _b[`x']

                    // semi-elasticity
                    * Check if xvar is binary. if yes, semi-elasticity formula is different
                    capture qui levelsof `x', local(levels)
                    local count_levels: word count `levels'

                    if (`count_levels' == 2) {
                        if (lower("`spec'") == "log") {
                            scalar semi_elasticity = exp(`beta') - 1
                        }
                        else {
                            local level0: word 1 of `levels'
                            local level1: word 2 of `levels'

                            tempvar uty_level0 uty_level1

                            local ty_level0 = `ty_`specname'_atmeans' - `beta' * `mean_`xx'' + `beta' * `level0'
                            local ty_level1 = `ty_`specname'_atmeans' - `beta' * `mean_`xx'' + `beta' * `level1'

                            gen double `uty_level0' = abs(`ty_level0' + `resid')^(1/(`spec')) * (2 * (`y' > 0) - 1) `if' `in'
                            gen double `uty_level1' = abs(`ty_level1' + `resid')^(1/(`spec')) * (2 * (`y' > 0) - 1) `if' `in'

                            sum `uty_level0', meanonly
                            local pred0 = r(mean)
                            sum `uty_level1', meanonly
                            local pred1 = r(mean)

                            local semi_elasticity = (`pred1'-`pred0')/(`pred0')/(`level1' - `level0')
                            drop `uty_level0' `uty_level1'
                        }
                    }
                    else {
                        if (lower("`spec'") == "log") {
                            local semi_elasticity = `beta'
                        }
                        else {
                            if (`count_at' > 0) {
                                local atval: word `ix' of `xvar_at'

                                if ("`atval'" == "atmeans") {
                                    local semi_elasticity = `beta'/(`spec')/`ty_`specname'_atmeans'
                                }
                                else {
                                    local ty_`specname'_at = `ty_`specname'_atmeans' - `beta' * `mean_`xx'' + `beta' * `atval'

                                    local semi_elasticity = `beta'/(`spec')/`ty_`specname'_at'
                                }
                            }
                            else {
                                local semi_elasticity = `beta'/(`spec')/`ty_`specname'_atmeans'
                            }
                        }
                    }
                    matrix Untransformed[`ix', `ispec'] = `semi_elasticity'
                    estadd scalar semi_`xx' = `semi_elasticity': `reg_pre'`specname'
                    local semi_`xx'_label `""semi_`xx' eydx: `lab_`xx''""'
                    local scalars_tregs `scalars_tregs' `semi_`xx'_label'

                    // elasticity
                    if (`count_levels' == 2) {
                        // binary, no elasticity
                        local elasticity = .
                    }
                    else {
                        if (`count_at' > 0) {
                            local atval: word `ix' of `xvar_at'
                            if ("`atval'" == "atmeans") {
                                sum `x', meanonly
                                local atval = r(mean)
                            }
                            local elasticity = `semi_elasticity' * `atval'
                        }
                        else {
                            sum `x', meanonly
                            local elasticity = `semi_elasticity' * r(mean)
                        }
                    }
                    matrix Untransformed[`ix' + `count_xvar', `ispec'] = `elasticity'
                    estadd scalar elas_`xx' = `elasticity': `reg_pre'`specname'
                    local elas_`xx'_label `""elas_`xx' eyex: `lab_`xx''""'
                    local scalars_tregs `scalars_tregs' `elas_`xx'_label'
                }

                * Predicted value at specific Xs or atmeans
                if ("`predicted_y'" != "" & strtrim("`predicted_y'") != "atmeans") {
                    margins `if' `in', `predicted_y' predict() nose
                    local transformed_predval = r(b)[1, 1]
                }
                else {
                    local transformed_predval = `ty_`specname'_atmeans'
                }

                tempvar untransformed_predval

                if (lower("`spec'") == "log") {
                    gen double `untransformed_predval' = exp(`transformed_predval' + `resid') `if' `in'
                }
                else {
                    gen double `untransformed_predval' = abs(`transformed_predval' + `resid')^(1/(`spec')) * (2 * (`y' > 0) - 1) `if' `in'
                }

                sum `untransformed_predval', meanonly
                local predval = r(mean)
                matrix Untransformed[`count_xvar' * 2 + 1, `ispec'] = `predval'
                estadd scalar pred = `predval': `reg_pre'`specname'
                local pred_label `""pred `predy_lab'""'
                local scalars_tregs `scalars_tregs' `pred_label'

                drop `untransformed_predval'


                * Scalars to be added depending on options
                local andrewslabel
                local resetlabel
                local shapiro_wilklabel

                if ("`andrewstest'" != "") | ("`resettest'" != "") {
                    estimates restore `reg_pre'`specname'

                    tempvar ty_hat
                    predict double `ty_hat' `if' `in'
                }

                * Evaluate model specification

                * Andrews 1971' test of linearity
                if ("`andrewstest'" != "") {
                    qui count if `ty_hat' < 0
                    if r(N) > 0 {
                        local p = .
                        display as result in smcl "Warning: The Andrews test of linearity does not applied with negative predicted values."
                    }
                    else {
                        tempvar v_hat
                        gen `v_hat' = `ty_hat' * ln(`ty_hat') `if' `in'

                        `reg_command' `ty_`specname'' `cnames' `v_hat' `if' `in' [`weight'`exp'], `regopts_nores' `absorb_option'
                        local p = r(table)["pvalue", "`v_hat'"]

                    }
                    estadd scalar andrewstest_p = `p': `reg_pre'`specname'
                    local andrewslabel `""andrewstest_p Andrews Test p""'
                }

                * Ramsey's RESET Test
                if "`resettest'"=="resettest" {
                    tempvar yh yh2 yh3 yh4
                    summ `ty_hat'
                    gen `yh' = (`ty_hat'-r(min))/(r(max)-r(min))
                    gen double `yh2' = `yh'*`yh'
                    gen double `yh3' = `yh'*`yh'*`yh'
                    gen double `yh4' = `yh'*`yh'*`yh'*`yh'
                    local rhs "`yh2' `yh3' `yh4'"
                    `reg_command' `ty_`specname'' `cnames' `rhs' `if' `in' [`weight'`exp'], `regopts_nores' `absorb_option'
                    if _se[`yh2']==0 & _se[`yh3']==0 & _se[`yh4']==0 {
                        display as result in smcl "Warning: The RESET specification test is not valid. Powers of fitted values collinear with explanatory variables (typically because all explanatory variables are indicator variables)."
                        local p = .
                    }
                    else {
                        test `yh2' `yh3' `yh4'
                        local p = r(p)
                    }
                    scalar reset_p = `p'
                    local resetlabel `""reset_p RESET Test p""'
                    estadd scalar reset_p: `reg_pre'`specname'
                }

                * Shapiro-Wilk test of normality
                if "`swilktest'"=="swilktest" {
                    swilk `resid'
                    scalar shapiro_wilk_p = r(p)
                    local shapiro_wilklabel `""shapiro_wilk_p Shapiro-Wilk Test p""'
                    estadd scalar shapiro_wilk_p: `reg_pre'`specname'
                }

                drop `resid'
            }
        }
    }

    local scalars_tregs `scalars_tregs' `resetlabel' `andrewslabel' `shapiro_wilklabel'
    local scalars_tregs = substr(`""`scalars_tregs'"', 3, .)

    cap drop _est*
    cap drop _reghdfe_resid

    *** Output results ***

    local lab_y: variable label `y'
    if "`lab_y'" == "" {
        local lab_y `y'
    }

    * Display regression table and specification tests
    esttab `reg_pre'*, se obslast noconstant label varwidth(25) ///
        title("Regression Results, Dep. Var: `lab_y'")	///
        mtitles(`colnames') scalars(`scalars_tregs')	///
        star(* 0.10 ** 0.05 *** 0.01)

    * Display semi-elasticities, elasticities, predicted value
    /* esttab matrix(Untransformed), varwidth(20) modelwidth(15) */

    return clear
    ereturn clear
    sreturn clear
    ereturn local cmd treg
    ereturn local cmdline treg `0'
    ereturn local speclist "`speclist'"
    ereturn local cnames "`cnames'"
    ereturn local y "`y'"
    ereturn local if "`if'"
    ereturn local in "`in'"
    ereturn local reg_command "`reg_command'"
    ereturn local weight "`weight'`exp'"
    ereturn local regopts "`regopts'"
    ereturn local absorb_option "`absorb_option'"
    if "`mostlinear'" != "" {
        ereturn local mostlinear_power = "`mostlinear_k'/99"
    }
    ereturn local mostlinear "`mostlinear'"
    ereturn local mtitles `colnames'
    ereturn matrix elasticities Untransformed

end

capture program drop simplify_fraction
program define simplify_fraction, eclass
    syntax, frac(string)

    local slash_pos = strpos("`frac'", "/")

    local num1 = substr("`frac'", 1, `slash_pos' - 1)
    local num2 = substr("`frac'", `slash_pos' + 1, .)
    local numerator = `num1'
    local denominator = `num2'
    while (`num2' != 0) {
        local temp = `num2'
        local num2 = mod(`num1', `num2')
        local num1 = `temp'
    }
    local numerator = round(`numerator'/`num1')
    local denominator = round(`denominator'/`num1')
    local frac `numerator'/`denominator'
    local val = `frac'
    if (`val' == int(`val')) {
        local frac = int(`val')
    }

    ereturn local simplified_frac `frac'
    ereturn local numerator `numerator'
    ereturn local denominator `denominator'
end

capture program drop p_k
program p_k, rclass
    syntax, k(real) depvar(string) cnames(string) [regopts(string)] [weightopts(string)] [if_opts(string)] [in_opts(string)] [absorb_option(string)]

    if "`absorb_option'" == "" {
        local reg_command reg
    }
    else {
        local reg_command reghdfe
    }

    local spec `k'/99

    quietly {
        tempvar ty
        gen `ty' = ( (abs(`depvar'))^(`spec') * (2*((`spec') > 0) - 1) ) * ( 2 * (`depvar' > 0) - 1 )
        `reg_command' `ty' `cnames' `if_opts' `in_opts' [`weightopts'], `regopts' `absorb_option'

        tempvar ty_hat
        predict `ty_hat' `if_opts' `in_opts'

        tempvar yh yh2 yh3 yh4
        summ `ty_hat'
        gen `yh' = (`ty_hat'-r(min))/(r(max)-r(min))
        gen double `yh2' = `yh'*`yh'
        gen double `yh3' = `yh'*`yh'*`yh'
        gen double `yh4' = `yh'*`yh'*`yh'*`yh'
        local rhs "`yh2' `yh3' `yh4'"
        `reg_command' `ty' `cnames' `rhs' `if_opts' `in_opts' [`weightopts'], `regopts' `absorb_option'

        if _se[`yh2']==0 & _se[`yh3']==0 & _se[`yh4']==0 {
            return scalar pvalue = -1
        }
        else {
            test `yh2' `yh3' `yh4'
            return scalar pvalue = r(p)
        }
    }
end

mata:
real scalar grid_search_k_init(string scalar depvar, string scalar cnames, string scalar regopts, string scalar weightopts, string scalar if_opts, string scalar in_opts, string scalar absorb_option, real scalar min_k, real scalar max_k, real scalar step_size) {

    real scalar best_k, current_pvalue, max_pvalue

    max_pvalue = -1
    best_k = min_k

    for (k = min_k; k <= max_k; k = k + step_size) {
        current_pvalue = get_pval(k, depvar, cnames, regopts, weightopts, if_opts, in_opts, absorb_option)

        if (current_pvalue > max_pvalue) {
            max_pvalue = current_pvalue
            best_k = k
        }
    }

    return(best_k)
}

real scalar get_pval(real scalar k, string scalar depvar, string scalar cnames, string scalar regopts, string scalar weightopts, string scalar if_opts, string scalar in_opts, string scalar absorb_option){
    real scalar pvalue
    stata("p_k, k(" + strofreal(k) + ") depvar(" + depvar + ") cnames(" + cnames + ") regopts(" + regopts + ") weightopts(" + weightopts + ") if_opts(" + if_opts + ") in_opts(" + in_opts + ") absorb_option(" + absorb_option + ")" )

    pvalue = st_numscalar("r(pvalue)")

    return(pvalue)
}

void find_max_pvalue(string scalar depvar, string scalar cnames, string scalar regopts, string scalar weightopts, string scalar if_opts, string scalar in_opts, string scalar absorb_option) {
    real scalar optimize_result
    real scalar k_grid
    real scalar min_k, max_k, step_size

    min_k = 1
    max_k = 99
    step_size = 1

    k_grid = grid_search_k_init(depvar, cnames, regopts, weightopts, if_opts, in_opts, absorb_option, min_k, max_k, step_size)

    (void) st_local("mostlinear_k_bounded", strofreal(k_grid))
}

end
