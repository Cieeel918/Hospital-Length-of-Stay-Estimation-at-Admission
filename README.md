# Hospital-Length-of-Stay-Estimation-at-Admission
The business objective of this program is to estimate the Length of stay(LOS) more accurately upon admission than  using the mean LOS.
## Data Exploration:
### 1、Distribution of Length.of.Stay (y)
The distribution of Length of Stay exhibits a significant right skew (as shown in Figure 1), with the majority of patients having relatively short stays (concentrated between 1 to 3 days), while a minority of patients have much longer stays, likely due to severe or complex medical conditions.

<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/c2e3a2f2-4002-4e3e-a8f0-ce8a481864f2"  width="400">
  <p>Figure 1: Distribution of Length of Stay</p>
</div>

To address this pronounced skewness and align the data with model assumptions, a log transformation (log1p) was applied to the Length of Stay variable. This transformation substantially reduced the skewness, resulting in a distribution closer to normal (Figure 2), which meets the assumptions of linear regression models and enhances performance in regression and prediction tasks.

<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/ea2ae05e-51df-4d72-adc2-e159c1fce23d"  width="400">
  <p>Figure 2  Log Transformed of Length of stay</p>
</div>

### 2、Relationship between Total.Charges,Total.Costs and Los: Predicting Los is meaningful for estimating the costs of stay in hospital.
Total Charges and Total Costs both exhibit severe right-skewness with many extreme outliers, as shown in  boxplots (Figure 3, histograms not shown in this report but shown in the Rscript). Similarly, Length of Stay (LOS) was capped at 120 days for any stays exceeding this limit. 

<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/ede5b14a-67ed-4b41-b314-9fc9c96bb97b"  width="400">
  <p>Figure 3 Boxplots of Total Charges and Total Costs</p>
</div>
<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/ffe0bd0b-ee70-4e00-bf2f-2ab379ea2f07"  width="400">
</div>

After removing the top 5% outliers and applying log transformation to both Total Costs and Total Charges, we found that LOS had a strong correlation with both variables (correlation coefficients of 0.8 and 0.71, respectively).This indicates that predicting LOS to inform patients about estimated costs and facilitate insurance approval is meaningful and can improve financial planning and resource allocation in hospitals.

<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/520d0d18-a793-415a-a83e-cec16a66085e"  width="400">
  <p>Figure 5 Correlation heatmap </p>
</div>

### 3、Length of Stay Increases Significantly with Age, Particularly for Patients Aged 50 and Above.The longest lengths of stay are observed in facilities requiring continuous care, such as rehabilitation centers, psychiatric hospitals, and nursing homes. In contrast, shorter stays are more common among patients who are discharged for self-care or leave against medical advice, likely due to milder conditions or personal choice (Figure 8).
There is a clear upward trend in the length of hospital stay (Length of Stay) as age increases, as shown in Figure 6. Particularly for patients aged 50 and above, the length of stay is significantly longer compared to younger age groups. This suggests that older patients tend to require more extended hospitalization, likely due to more complex health conditions or the need for more intensive care. And the distribution of total charges (Total Charges) across age groups has the same pattern (Figure 7), so older groups may contribute to higher overall healthcare costs and charges, there is a need for more strategic allocation of medical resources, with particular attention to older age groups.
<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/da798184-b4cd-41c2-9c21-d005da608816"  width="400">
  <p>Figure 6 Average Length of Stay by age group</p>
</div>
<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/de26bf15-9f0b-479d-8a49-13aea4ff9662"  width="400">
  <p>Figure 7 Distribution of charges across age groups</p>
</div>
<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/64c3b1f1-6cc7-4931-8635-72eb16bc82c4"  width="400">
  <p>Figure 8 Average Length of Stay by Disposition</p>
</div>

- Data preparation needed mention:

When outliers in total charges and total costs were removed by trimming the top 5%, the corresponding outliers in length of stay (LOS) were also excluded. Statistical analysis of the cleaned data shows that the maximum LOS is now 99 days, eliminating the impact of extreme values such as stays over 120 days.

Since Total Cost and Total Charges are incurred during the hospital stay, they are more suitable for post-analysis rather than being used as explanatory variables in a prediction model at the time of admission, so removing them from dataset.

Hospital.Service.Area and APR.Risk.of.Mortality: Rows with missing values in these columns were removed.

Gender: Rows with the value "U" (unknown gender) were removed, and unused factor levels were dropped.

Payment.Typology.2 and Payment.Typology.3: Missing values in these payment type variables were replaced with "not use payment 2" or "not use payment 3" and were converted to factor variables.

APR.DRG.Code: After removing the descriptive variable APR.DRG.Description, APR.DRG.Code was converted to a nominal (unordered) factor since it has no intrinsic order.

CCSR.Diagnosis.Code and CCSR.Diagnosis.Description: CCSR.Diagnosis.Description was removed because CCSR.Diagnosis.Code was not ordinal and had only one unique value, making it meaningless. The code column was also removed.

APR.Severity.of.Illness.Code and APR.Severity.of.Illness.Description: The descriptive variable was dropped, and APR.Severity.of.Illness.Code was converted to an ordinal factor with levels ranging from 0 to 4.
<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/ae07cc4f-5f3e-4177-8f1b-98d00cfc41f6"  width="600">
</div>


## State the list of potential predictor X variables and Models used
![image](https://github.com/user-attachments/assets/911e2f5c-2843-4cc2-a4e1-9c7b1ca0c78f)
<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/256f921c-5445-47d0-9676-16fbde763e7f"  width="600">
</div>



## Models’ results and  Insights for the business application
### 1、Linear regression
Model Fit: The adjusted R² is 0.7598, meaning the model explains about 76% of the variance in
Length of Stay. The p-value is less than 2.2e-16, indicating the model is statistically significant.
![image](https://github.com/user-attachments/assets/e7eb1057-99b8-4b6d-b84b-fd7ced7039ed)
Multicollinearity: VIF shows nearly no multicollinearity.

Heteroscedasticity: Both the Residuals vs Fitted and Scale-Location plots show a fan-shaped pattern(Figure 9),indicating somewhat heteroscedasticity.

Outliers and Leverage Points: Some points (e.g., 5423, 9896, 4098) show high leverage, and a few outliers (e.g., 13801, 11209, 1305) were identified, but no adjustments were made due to their small number.
<div style="text-align: center;">
  <img src="https://github.com/user-attachments/assets/c0f50b2f-8c33-48a7-bd4e-51915e8482a9"  width="600">
</div>

Error Rate: RMSE on the test set is 5.68, indicating the model's predicted Length of Stay deviates from the actual values by an average of 5.68 units.

- Insight: Length of stay is significantly influenced by patient deposition, hospital service areas, patient age and payment methods, providing critical direction for resource allocation, cost management, and financial risk assessment in hospital operations.
  
Patients discharged to facilities requiring extended care, such as rehabilitation centers or nursing homes, have significantly longer hospital stays, while those discharged home or leaving against medical advice have shorter stays. This suggests that hospitals should prioritize resource allocation for patients requiring post-hospitalization care.

Patients in the "Finger Lakes" region have longer stays, while those in "Long Island" and "Hudson Valley" show shorter duration. This suggests hospitals should optimize bed and resource allocation based on regional patient needs. Older patients require significantly longer hospitalization, indicating the need for focused resource planning in departments serving elderly populations, such as specialized staff and equipment. Self-pay patients tend to have shorter stays, while Medicaid and Medicare patients experience longer duration. Understanding this can help hospitals better assess financial risks and develop tailored financial plans for patients based on their payment types.  Severity of illness significantly prolongs the length of stay, suggesting that hospitals should prioritize care resources for severe cases to improve resource utilization and patient flow.

### 2、Cart
<img width="640" alt="image" src="https://github.com/user-attachments/assets/9dc0fa4c-346b-45a1-9e37-22c5733284a6">

The CART model after pruning demonstrates good performance in predicting Length of Stay (LOS), with an RMSE of 5.799708, indicating low prediction error on the test set. The model has been pruned to an optimal complexity parameter (cp = 0.004524852), resulting in 9 terminal nodes, which balance model complexity with adequate predictive power. 

At the optimal pruning point (cp = 0.004524852), the relative error is 0.8013, indicating a 19.9% improvement in error reduction compared to the unpruned model. The standard error remains stable throughout pruning, with a value of 0.02693 at the optimal point, indicating consistency in model performance across different folds.However, a relative error of 0.8013 suggests room for further improvement, possibly through tuning or alternative models.

As shown in the Figure 10, we can get the variable importance in predicting the length of stay in the Cart.Patient Disposition (45%): This is the most influential variable. Patients discharged to rehabilitation or long-term care facilities tend to have longer stays, while those discharged to self-care or who leave early typically have shorter stays. This highlights the need for more resource planning for patients requiring extended care; APR Severity of Illness Code(20%) : As the severity of illness increases, LOS also extends. Patients with more severe conditions require prolonged care and treatment, indicating the need for greater allocation of hospital resources, such as specialized care and beds; APR Risk of Mortality(14%): Higher mortality risk correlates with longer LOS, as these patients generally require more intensive monitoring and treatment. This underscores the necessity of ensuring adequate medical equipment and staff for high-risk patients.

<img width="640" alt="image" src="https://github.com/user-attachments/assets/b9aa5cf9-7f4f-49db-b047-25bc94e830b9">

- Insight: The variable importance analysis shows that the most significant factors affecting length of stay (LOS) are Patient Disposition, APR Severity of Illness Code, and APR Risk of Mortality. These variables provide key insights into the factors driving hospital stay duration.

### 3、Random forest

<img width="640" alt="image" src="https://github.com/user-attachments/assets/d476ff5a-f039-4ed3-ab1d-6ab7a444407e">

The evaluation results of the random forest model indicate that after fine-tuning the parameters, the optimal number of trees is 500 and the best number of features (RSF) is 5, as determined through bootstrap sampling and RSF selection. This tuning process minimized the OOB error to 35.36801, and the RMSE on the test set is 5.776239.

- Insight: The variable importance plot(Figure 11) reveals that the most significant contributors to predicting length of stay are Patient Disposition, Hospital Service Area, APR Severity of Illness Code, and Payment Typology. These findings suggest that hospitals should prioritize these key variables in resource planning and patient management, especially regarding post-discharge resource allocation and varying healthcare demands across service areas.

<img width="640" alt="image" src="https://github.com/user-attachments/assets/2ce92b0a-e8b5-4434-98d6-145641488d46">

### 4、Conclusion and Comparison among models
The linear regression model has the lowest RMSE (5.681781), indicating slightly better predictive performance compared to the CART and Random Forest models, although all models are relatively close in performance and variable importance.

Patient Disposition and APR Severity of Illness Code are the most important predictors across models, suggesting hospitals should focus on these variables to refine resource allocation and predict patient outcomes. This insight can be extended by analyzing interaction effects between disposition and severity, which could provide more granularity in predicting longer stays for certain patient profiles.

## Improvements
### 1、Improve the  model performance and accuracy but lower the generalization ability
If the goal is to improve the accuracy not the generalization, an improvement can be made by removing the outliers, although this may reduce their generalization ability. The RMSE of the model can be improved through dropping out more outliers, which will narrow the range of depend variable of the dataset. For example, the Q3 + 1.5*IQR can be regarded as a bound of outliers which is 20.5 in this case. 

Given this solution, he previously obtained optimal model, the linear regression model, was retrained, resulting in an improved RMSE on the test set: 3.858132. On the one hand, this lower RMSE means a more precise prediction on length of stay for the majority of patients. On the other hand, deleting more so-called outliers will lead to information loss, so the model will lose generalization to some extent. But this method can still be regarded as an option when design this model, if the target is to minimize the error.
<img width="400" alt="image" src="https://github.com/user-attachments/assets/f4fcbbe5-c5bd-4797-a980-535a48da6fd4">


### 2、Variable Selection Improvement
The selection of variables is reasonable in capturing key aspects such as patient demographics (age, gender, race), clinical factors (APR Severity of Illness, APR Risk of Mortality), and administrative aspects (Payment Typology, Hospital Service Area). However, more focus on medical history or prescription drugs could improve the prediction of LOS as these factors significantly influence patient outcomes. For example, incorporating data on past hospitalizations or chronic conditions could improve predictive power.

The choice of not using Total Charges and Total Costs as explanatory variables due to them being incurred post-admission aligns with the objective of predicting LOS at admission. But if available, future iterations of the model could include pre-admission cost estimates or financial risk factors.

The hospital service area variable could be further explored by clustering analysis, clustering the hospitals group based on similar characteristics, such as bed availability, nurse-to-patient ratio, to examine regional differences and their impact on LOS more deeply.

### 3、Model Selection Improvement
Linear Regression: While linear regression provides a useful baseline with interpretable coefficients and shows the least RMSE among these three models, it may oversimplify the relationships, especially with complex nonlinear factors influencing Length.of.stay. Incorporating regularization techniques (like Lasso or Ridge regression) might improve performance by addressing multicollinearity and reducing overfitting.

Cart: The CART model has been pruned to reduce complexity. However, the relative error of 0.8013 suggests the model could still be further improved. Consider exploring Gradient Boosting or XGBoost, which might perform better than CART in handling interactions between variables and improving prediction accuracy.

Random Forest: While Random Forest is effective in reducing variance and improving robustness, trying other more professional techniques like Extreme Random Trees or Gradient-Boosted Trees could lead to improved performance.

### 4、Post-LOS Prediction Improvements for hospital management
After predicting LOS, hospitals could use these insights to optimize resource allocation. For instance, patients predicted to have longer stays could be preemptively assigned to specialized care units with appropriate and accurate staffing and equipment.

Hospitals could implement dynamic capacity management systems that adjust resource allocations in real-time based on predicted LOS, thus improving bed turnover rates and reducing medical resource strain.

