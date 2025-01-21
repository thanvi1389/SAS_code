Objective: 
A macro to perform multiple linear regression using ordinary least squares (OLS) estimation from first principles using PROC IML. The implementation avoids using built-in linear regression function, focusing instead on coding the mathematical computations for regression. 
  
Function Overview: The %ols_reg macro performs multiple linear regression and outputs: 
1.	Parameter estimates for predictors. 
2.	Standard errors of estimates. 
3.	R-squared and adjusted R-squared statistics. 
4.	Optional ANOVA results, including F-statistic and p-values. 

Parameters:  
1.	data: The input dataset containing the outcome and predictor variables. 
2.	outcome: The dependent (outcome) variable.  
3.	predictor: A space-separated list of independent (predictor) variables 
4.	miss: The value that indicates missing data in the dataset (default: .).
5.	reg: Controls whether ANOVA results are included. Default is Y (include ANOVA).
6.	format: Specifies the output format - P: PDF; R: RTF  
        	
How to Use %ols_reg: 
Set Path: Specify the directory containing the macro and dataset: 
eg:     
%let path = /home/u63980097/sasuser.v94/SAS_Thanwi/BS803;	  
libname BS803 "&path.";  
%include "&path./ols-reg.sas";  

1.	Prepare the Dataset: Ensure your dataset is accessible in the specified library. 
2.	Run the Macro: Call the macro with the required parameters as shown in the example above. 
3.	Locate the Output: Check the specified directory for the output file (_ols_results.pdf or _ols_results.rtf). 
 
Syntax : %ols_reg(data=dataset, outcome=dependent_variable, predictor= list of variables, miss=missing_value_code, reg=Y_or_N, format=output_format);  
  
Example Run: %ols_reg(data=bs803.framdat2, outcome=DTH, predictor=AGE SEX CHD SPF GLI CSM FVC, format=P); 
  
 
