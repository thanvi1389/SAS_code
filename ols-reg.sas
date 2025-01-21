************************************************************************************************;
*Title       :  ols-reg                                                            ;
*Author      :  Thanwi Anna Lalu                                                                ;
*Program Name:  ols-reg                                                                         ;
*Description :  Macro to run multiple linear regression                                         ; 
*-----------------------------------------------------------------------------------------------;
**********************************Macro Usage - Read Me*****************************************;
*-----------------------------------------------------------------------------------------------;                
*data        : Dataset containing the variables including library eg: BS803.FHS                 ;
*outcome     : Outcome variable eg: outcome=dth                                                 ;
*predictor.  : Model predictors seperated by space eg: predictor=AGE SEX CHD CSM GLI FVC MRW SPF;
*miss        : If in the dataset missing values are coded by someother values specify the value
               eg: if missing is coded by -99, then miss=-99., By default it just checks for '.';
*reg         : If you need only the paramter estimates and goodness of fit test give reg=N, 
               by default anova test will be printed.                                           ;
*format      : If you want the output in i) pdf give format=P, ii)rtf give format=R            
*example     : %ols_reg(data=bs803.fhs,outcome=DTH,predictor= AGE SEX CHD SPF,miss=-99,reg=N,
               format=P)   ;
************************************************************************************************;

%macro ols_reg(data=, outcome=, predictor=, miss=., reg=Y,format=);
 
    /* Start the ODS output formatting based on the specified format */
    %if "&format."="P" %then %do; ods pdf file="&path./ols_results.pdf" style= statistical; %end;
    %if "&format."="R" %then %do; ods rtf file="&path./ols_results.rtf" style= statistical; %end;
  
	proc iml;
		/* Step 1: Reading the data */
		use &data.;
		read all var {&outcome.} into y;
		read all var {&predictor.} into X;

		/* Step 2: Handle missing values  */
		total_row=nrow(y);

		do i=1 to nrow(y);

			/* Replace coded missing values with . */
			if y[i]=&miss. then
				y[i]=.;

			do j=1 to ncol(X);

				if X[i, j]=&miss. then
					X[i, j]=.;
			end;
		end;

		/* Find rows with no missing values for all variables in the model*/
		complete_cases=loc(^(X=. | y=.)[, :]);
		y_complete=y[complete_cases];
		X_complete=X[complete_cases, ];
		obs_used=nrow(y_complete);
		miss_obs=total_row - obs_used;

		if nrow(X_complete)=0 then
			do;
				print "Error: All data has missing values after listwise deletion.";
				return;
			end;

		/* Add intercept */
		intercept=j(nrow(X_complete), 1, 1);
		X_complete=intercept || X_complete;

		/* Step 3: Calculate OLS Estimates (beta_hat) */
		beta_hat=inv(X_complete` * X_complete) * X_complete` * y_complete;

		/* Step 4: Calculate residuals, standard errors, and sigma^2 */
		y_hat=X_complete * beta_hat;
		residuals=y_complete - y_hat;
		n=nrow(X_complete);
		p=ncol(X_complete);
		sigma_squared=(residuals` * residuals) / (n - p);
		cov_beta_hat=sigma_squared * inv(X_complete` * X_complete);
		se_beta_hat=sqrt(vecdiag(cov_beta_hat));

		/* Step 5: t-values and p-values for each coefficient */
		t_values=beta_hat / se_beta_hat;
		df=n - p;
		p_inter=2 * (1 - cdf("t", abs(t_values), df));
		p_value=j(nrow(p_inter), 1, "            ");

		do i=1 to nrow(p_inter);

			if p_inter[i] <.0001 then
				p_value[i]='<.0001';
			else
				p_value[i]=strip(putn(round(p_inter[i], .0001), '12.4'));
		end;

		/* Step 6: Calculate ANOVA components */
		ss_total=sum((y_complete - mean(y_complete))##2);
		ss_residual=sum(residuals##2);
		ss_regression=ss_total - ss_residual;
		ms_regression=ss_regression / (p - 1);
		ms_error=ss_residual / df;
		root_mse=sqrt(ms_error);
		f_stat=ms_regression / ms_error;

		/* p-value for the F-statistic */
		if 1 - cdf("F", f_stat, p-1, df) < .0001 then
			p_value_f='<.0001';
		else
			p_value_f=strip(put(round(1 - cdf("F", f_stat, p-1, df), .0001), 12.4));

		/* Step 7: Additional Regression Statistics*/
		r_squared=1 - (ss_residual / ss_total);
		r_squared_adj=1 - (1 - r_squared) * ((n - 1) / (n - p));
		dependent_mean=mean(y_complete);
		coeff_var=(root_mse / dependent_mean) * 100;

		/* Step 8: Printing all outputs*/
		print 
			"Linear Regression Results for Dependent Variable: &&outcome." ;

		/* Print observation summary */
		print "Observation Summary:";
		headers_dat={"Observations Read" "Observations Used" 
			"Observations with Missing Values"};
		obs_sum=total_row || obs_used || miss_obs;
		print obs_sum[colname=headers_dat];

		/* Combine parameter estimates into a single matrix */
		headers={"Beta" "SE" "t-value"};
		predictor={Intercept &predictor.}`;
		Estimate=round(beta_hat, .00001) || round(se_beta_hat, .00001) 
			|| round(t_values, .01);
		print "Parameter Estimates:";
		print predictor Estimate[colname=headers] p_value;

		/*Display additional statistics */
		stats_summary=round(root_mse, .00001) || round(r_squared, .0001) 
			|| round(r_squared_adj, .0001) || round(dependent_mean, .00001) 
			|| round(coeff_var, .00001);
		stats_headers={"Root MSE" "R-Square" "Adj R-Sq" "Dependent Mean" "Coeff Var"};
		print "Model Summary Statistics:";
		print stats_summary[colname=stats_headers];

		/*Anova*/
		
		%if &reg=Y %then
			%do;
				print "Analysis of Variance:";
				Model=p-1 || round(ss_regression) || round(ms_regression, .00001) 
					|| round(f_stat, .01);
				Error=df || round(ss_residual) ||round(ms_error, .00001);
				Corrected_Total=df+p-1 || round(ss_total);
				Model_header={"DF" "Sum of Squares" "Mean Square" "F Value"};
				print Model[colname=Model_header] p_value_f;
				print Error[colname=Model_header];
				print Corrected_Total[colname=Model_header];
			%end;
	quit;
	/* Close the ODS output */
    %if "&format"="P" %then  ods pdf close; 
    %if "&format"="R" %then ods rtf close;
        
		
	%mend ols_reg;
