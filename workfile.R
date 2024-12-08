# Subject: Hospital Length of Stay Estimation at Admission

library(data.table)
library(caTools)           
library(rpart)        
library(randomForest) 
library(ggplot2)
library(car)
library(ggcorrplot)
library(DescTools)
library(gridExtra)

#----------------------------------------Data Cleaning--------------------------------------
dt <- fread('INF002v4.csv',na.strings = c("", "NA"),stringsAsFactors = T)
dt[dt == ""] <- NA  
sum(is.na(dt))


# column names
colnames(dt)
columns='
[1] "Hospital.Service.Area"               "Age.Group"                          
[3] "Gender"                              "Race"                               
[5] "Ethnicity"                           "Length.of.Stay"                     
[7] "Type.of.Admission"                   "Patient.Disposition"                
[9] "Discharge.Year"                      "CCSR.Diagnosis.Code"                
[11] "CCSR.Diagnosis.Description"         "APR.DRG.Code"                       
[13] "APR.DRG.Description"                 "APR.Severity.of.Illness.Code"       
[15] "APR.Severity.of.Illness.Description" "APR.Risk.of.Mortality"              
[17] "APR.Medical.Surgical.Description"    "Payment.Typology.1"                 
[19] "Payment.Typology.2"                  "Payment.Typology.3"                 
[21] "Emergency.Department.Indicator"      "Total.Charges"                      
[23] "Total.Costs" '

summary(dt)
# Discharge.Year only has one year,remove it
unique(dt$Discharge.Year) #[1] 2022
dt <- dt[,!"Discharge.Year"]

# convert Total.Charges and Total.Costs into numeric
dt[, Total.Charges := as.numeric(gsub(",", "", as.character(Total.Charges)))]
dt[, Total.Costs := as.numeric(gsub(",", "", as.character(Total.Costs)))]


## check explanatory variable' duplication and rationality
# APR.DRG.Code and APR.DRG.Description(norminal): guess no order,remain code that does not take up too much memory
# CCSR.Diagnosis.Code 和 CCSR.Diagnosis.Description(norminal): guess no order, the same as DRG Code and reamin code
# APR.Severity.of.Illness.Code 和 APR.Severity.of.Illness.Description(ordinal):remain one,and has order,check order
dt <- dt[,!"APR.DRG.Description"] 
dt[, APR.DRG.Code := factor(APR.DRG.Code, ordered = FALSE)]
is.ordered(dt$APR.DRG.Code)  # falce,check if this code has order and ensure it is a nominal facotr variable
unique(dt$APR.DRG.Code)

dt <- dt[,!"CCSR.Diagnosis.Description"]
is.ordered(dt$CCSR.Diagnosis.Code)  # falce
unique(dt$CCSR.Diagnosis.Code)  # only has one level,it is no meaning,so remove
dt <- dt[,!"CCSR.Diagnosis.Code"]

dt <- dt[,!"APR.Severity.of.Illness.Description"] 
is.ordered(dt$APR.Severity.of.Illness.Code)  # falce, need to convert it into ordinal factor
dt[,APR.Severity.of.Illness.Code := factor(APR.Severity.of.Illness.Code,levels=c(0,1,2,3,4), ordered=TRUE)]
levels(dt$APR.Severity.of.Illness.Code)

#Emergency.Department.Indicator and Type.of.Admission: process in the late session

## check age group order
is.ordered(dt$Age.Group) 
dt[,Age.Group := factor(Age.Group,levels=c("0 to 17", "18 to 29", "30 to 49", "50 to 69", "70 or Older"), ordered=TRUE)]
levels(dt$Age.Group)


## check factor order
dt[, Hospital.Service.Area := factor(Hospital.Service.Area, ordered = FALSE)]
dt[, Gender := factor(Gender, ordered = FALSE)]
dt[, Race := factor(Race, ordered = FALSE)]
dt[, Type.of.Admission := factor(Type.of.Admission, ordered = FALSE)]
dt[, Patient.Disposition := factor(Patient.Disposition, ordered = FALSE)]
dt[, APR.DRG.Code := factor(APR.DRG.Code, ordered = FALSE)]

dt[, APR.Risk.of.Mortality := factor(APR.Risk.of.Mortality, levels = c("Minor", "Moderate", "Major", "Extreme"), ordered = TRUE)]
levels(dt$APR.Risk.of.Mortality)

dt[, APR.Medical.Surgical.Description := factor(APR.Medical.Surgical.Description, ordered = FALSE)]
dt[, Payment.Typology.1 := factor(Payment.Typology.1, ordered = FALSE)]
dt[, Payment.Typology.2 := factor(Payment.Typology.2, ordered = FALSE)]
dt[, Payment.Typology.3 := factor(Payment.Typology.3, ordered = FALSE)]


## clean na value and unknown value
summary(dt)
dt <- dt[!is.na(Hospital.Service.Area) & !is.na(APR.Risk.of.Mortality)]
dt <- dt[Gender != "U"]
dt[, Gender := droplevels(Gender)]
#Payment.Typology.2 and Payment.Typology.3: change the null value
# change the na in Payment.Typology.2 into "not use payment 2"
dt[, Payment.Typology.2 := factor(Payment.Typology.2, levels = c(levels(Payment.Typology.2), "not use payment 2"))]
dt[is.na(Payment.Typology.2), Payment.Typology.2 := "not use payment 2"]
dt[, Payment.Typology.3 := factor(Payment.Typology.3, levels = c(levels(Payment.Typology.3), "not use payment 3"))]
dt[is.na(Payment.Typology.3), Payment.Typology.3 := "not use payment 3"]

# dt is the clean data
dt_clean <- dt
summary(dt) #dont make change on the dt

#-------------------------------------------------Data Exploration---------------------------------
# 1.distribution of y: lenth.of.stay is severely right-skewed ，Log Transformation，make it more normal distributed and fit for model
hist(dt$Length.of.Stay, 
     main = "Distribution of Length of Stay", 
     xlab = "Length of Stay", 
     ylab = "Frequency", 
     col = "lightblue", 
     breaks = 20)
# los is severely right-skewed ，Log Transformation，make it more normal distributed and fit for model
dt[, log_los := log1p(Length.of.Stay)]
hist(dt$log_los, 
     main = "Log Transformed Length of Stay", 
     xlab = "Log(Length of Stay + 1)", 
     col = "lightblue", 
     breaks = 20)
plot(density(dt$log_los, na.rm = TRUE), 
     main = "Density Plot of Log Transformed Length of Stay", 
     xlab = "Log(Length of Stay + 1)", 
     col = "blue")
# log(length of stay + 1) is nearly normal distributed

# 2.distribution of numeric variable(total.charges and total costs): too much outliers in both variables
# Total Charges histogram：severely right-skewed
ggplot(dt, aes(x = Total.Charges)) +
  geom_histogram(binwidth = 10000, fill = "lightblue", color = "black") +  
  labs(title = "Histogram of Total Charges",
       x = "Total Charges",
       y = "Frequency") +
  theme_minimal()

# Total Costs histogram：severely right-skewed
ggplot(dt, aes(x = Total.Costs)) +
  geom_histogram(binwidth = 1000, fill = "lightgreen", color = "black") +
  labs(title = "Histogram of Total Costs",
       x = "Total Costs",
       y = "Frequency") +
  theme_minimal()

# Total Charges boxplot:many outliers
c1<-ggplot(dt, aes(y = Total.Charges)) +
  geom_boxplot(fill = "lightblue") +
  labs(title = "Boxplot of Total Charges",
       y = "Total Charges") +
  theme_minimal()

# Total Costs boxplot：many outliers 
c2<-ggplot(dt, aes(y = Total.Costs)) +
  geom_boxplot(fill = "lightpink") +
  labs(title = "Boxplot of Total Costs",
       y = "Total Costs") +
  theme_minimal()
grid.arrange(c1, c2, ncol = 2)  
# preprocess:total.charges and total costs
# delete last 5% outliers,useful for both lm 
threshold_charges <- quantile(dt$Total.Charges, 0.95, na.rm = TRUE)
threshold_costs <- quantile(dt$Total.Costs, 0.95, na.rm = TRUE)
dt_filtered <- dt[Total.Charges <= threshold_charges & Total.Costs <= threshold_costs]
# after delete : log transformation for linear regression
dt_filtered[, log_Total.Charges := log1p(Total.Charges)]
dt_filtered[, log_Total.Costs := log1p(Total.Costs)]


#correlation analysis: 
cor_matrix <- cor(dt_filtered[, .(log_Total.Charges, log_Total.Costs, log_los)], use = "complete.obs")
print(cor_matrix)
ggcorrplot(cor_matrix,method = "square",lab = TRUE,title = "Corr between los,totalcosts and totalcharges")



#4.exploration on meaningful categorial variable
#4a.Age.Group: 
p1 <- ggplot(dt_filtered, aes(x = Age.Group, y = log_Total.Charges)) +
  geom_boxplot(fill = "lightblue") +
  labs(title = "Total Charges by Age Group", 
       x = "Age Group", 
       y = "Log Transformed Total Charges") +
  theme_minimal()

p2 <- ggplot(dt_filtered, aes(x = Age.Group, y = log_los)) +
  geom_boxplot(fill = "lightblue") +
  labs(title = "Length of Stay by Age Group", 
       x = "Age Group", 
       y = "Log Transformed Length of Stay") +
  theme_minimal()
grid.arrange(p1, p2, nrow = 2)  
# Average Length of Stay by Age Group
mean_los_age <- aggregate(Length.of.Stay ~ Age.Group, data = dt_filtered, FUN = mean)
ggplot(mean_los_age, aes(x = Age.Group, y = Length.of.Stay)) +
  geom_bar(stat = "identity", fill = "lightblue",width = 0.6) +
  labs(title = "Average Length of Stay by Age Group", 
       x = "Age Group", 
       y = "Average Length of Stay") +
  theme_minimal()

#4b. Average Length of Stay by Gender
mean_los_gender <- aggregate(Length.of.Stay ~ Gender, data = dt_filtered, FUN = mean)
ggplot(mean_los_gender, aes(x = Gender, y = Length.of.Stay)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  labs(title = "Average Length of Stay by Gender", 
       x = "Gender", 
       y = "Average Length of Stay") +
  theme_minimal()

#4c.check racial bias：Black/African American 
mean_los_race <- aggregate(Length.of.Stay ~ Race, data = dt_filtered, FUN = mean)
ggplot(mean_los_race, aes(x = Race, y = Length.of.Stay)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  labs(title = "Average Length of Stay by Race", 
       x = "Race", 
       y = "Average Length of Stay") +
  theme_minimal()

#4d：Relationship between APR Risk of Mortality and APR Severity of Illness Code, their influence on lenth of stay
mean_los_mortality <- aggregate(Length.of.Stay ~ APR.Risk.of.Mortality, data = dt_filtered, FUN = mean)
mean_los_severity <- aggregate(Length.of.Stay ~ APR.Severity.of.Illness.Code, data = dt_filtered, FUN = mean)
print(mean_los_mortality )
print(mean_los_severity)
p1 <- ggplot(mean_los_mortality, aes(x = APR.Risk.of.Mortality, y = Length.of.Stay)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  labs(title = "Average Length of Stay by APR Risk of Mortality", 
       x = "APR Risk of Mortality", 
       y = "Average Length of Stay") +
  theme_minimal()+
  theme(panel.background = element_blank())
p2 <- ggplot(mean_los_severity, aes(x = APR.Severity.of.Illness.Code, y = Length.of.Stay)) +
  geom_bar(stat = "identity", fill = "lightpink") +
  labs(title = "Average Length of Stay by APR Severity of Illness Code", 
       x = "APR Severity of Illness Code", 
       y = "Average Length of Stay") +
  theme_minimal()
grid.arrange(p1, p2, nrow = 2)  

#4e. Los group by Inpatient Rehabilitation Facility
mean_los_Disposition <- aggregate(Length.of.Stay ~ Patient.Disposition, data = dt_filtered, FUN = mean)
mean_los_Disposition <- mean_los_Disposition[order(mean_los_Disposition$Length.of.Stay, decreasing = TRUE), ]
ggplot(mean_los_Disposition, aes(x = reorder(Patient.Disposition, Length.of.Stay), y = Length.of.Stay)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  labs(title = "Average Length of Stay by Disposition", 
       x = "Patient Disposition", 
       y = "Average Length of Stay") +
  coord_flip() +  
  theme_minimal()

#4f:Type.of.Admission and Emergency.Department.Indicator are two different dimensions
table(dt_filtered$Type.of.Admission, dt_filtered$Emergency.Department.Indicator)

# Since Total Cost and Total Charges are incurred during the hospital stay, 
# they are more suitable for post-analysis rather than being used as explanatory variables in a prediction model at the time of admission,so removing them from dataset.
dt_filtered$Total.Charges <- NULL
dt_filtered$Total.Costs <- NULL
dt_filtered$log_Total.Charges <- NULL
dt_filtered$log_Total.Costs <- NULL

summary(dt_filtered)
col_dt_filitered <- colnames(dt_filtered)
col_dt_filitered
fwrite(dt_filtered, "filitered_data.csv")


#---------------------------------------------------Linear regression-----------------------------------
dt_lm <- dt_filtered
colnames(dt_lm)
#------------train-test split
set.seed(1)
train <- sample.split(Y=dt_lm$log_los, SplitRatio = 0.7)
trainset <- dt_lm[train == T]
testset <- dt_lm[train == F]
#-------------step regression
lr <- step(lm(log_los ~ Hospital.Service.Area + Age.Group + Gender + Race + Ethnicity +
                Type.of.Admission + Patient.Disposition + APR.DRG.Code +
                APR.Severity.of.Illness.Code + APR.Risk.of.Mortality + 
                APR.Medical.Surgical.Description + Payment.Typology.1 + 
                Payment.Typology.2 + Payment.Typology.3 + Emergency.Department.Indicator, data = trainset)) 
##use step()to do stepforward linear regression 
summary(lr) #Adjusted R-squared:  0.2969 ; p-value: < 2.2e-16

# Multilinear: all well done
vif(lr)

#Diagnostic plots: Some points (e.g., 13482, 16846, 15748) are located in high leverage positions and are far from other points. Cases 9103 and 14901 are outliers. However, since the number of such points is small, no adjustments will be made.
#Both the Residuals vs Fitted and Scale-Location plots show a fan-shaped pattern, indicating the presence of heteroscedasticity. This suggests that the variance increases as the fitted values increase.
#The assumption of homoscedasticity of residuals is not satisfied, indicating that using linear regression for modeling may not be appropriate.
par(mfrow = c(2, 2), mar = c(4, 4, 2, 2)) 
plot(lr)

# calculate error rate:
lr_log.yhat <- predict(lr, newdata = testset)
lr.yhat <- exp(lr_log.yhat)
RMSE.test.lr <- sqrt(mean((testset$Length.of.Stay-lr.yhat)^2))
RMSE.test.lr
# 5.681781



#-------------------------------------------------------Cart----------------------------------------------------
dt_cart <- dt_filtered
colnames(dt_cart)
dt_cart <- dt_cart[,!"log_los"]
#------------train-test split
set.seed(1)
train <- sample.split(Y=dt_cart$Length.of.Stay, SplitRatio = 0.7)
trainset <- dt_cart[train == T]
testset <- dt_cart[train == F]

cart.max <- rpart(Length.of.Stay ~ . , method='anova',cp=0, data=trainset)
cart.yhat_max <- predict(cart.max, newdata = testset)
#evaluate the prediction
RMSE.test.cart_max <- sqrt(mean((testset$Length.of.Stay - cart.yhat_max)^2)) #6.075671


## Compute min CVerror + 1SE in maximal tree 
CVerror.cap <- cart.max$cptable[which.min(cart.max$cptable[,"xerror"]), "xerror"] + 
  cart.max$cptable[which.min(cart.max$cptable[,"xerror"]), "xstd"]

##use 1SE rule to find the optimal cap
i <- 1; j<- 4
while (cart.max$cptable[i,j] > CVerror.cap) {
  i <- i + 1
}
# i=9

# Get geometric mean of the identified min CP value and the CP above if optimal tree has at least one split.
cp.opt = ifelse(i > 1, sqrt(cart.max$cptable[i,1] * cart.max$cptable[i-1,1]), 1)
# cp.optimal = 0.004524852

# Get best tree based on 10 fold CV with 1 SE
cart.opt <- prune(cart.max, cp = cp.opt)
print(cart.opt)
printcp(cart.opt)
summary(cart.opt)
# terminal node= 9

#predict on the test set
cart.yhat <- predict(cart.opt, newdata = testset)
#evaluate the prediction
RMSE.test.cart <- sqrt(mean((testset$Length.of.Stay - cart.yhat)^2))
RMSE.test.cart 
##5.799708

# extract variable.importance：
var_imp <- cart.opt$variable.importance
var_imp_df <- data.frame(Variable = names(var_imp), Importance = var_imp)
ggplot(var_imp_df, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  coord_flip() +  
  labs(title = "Variable Importance", x = "Variables", y = "Importance") +
  theme_minimal()

var_imp_df$Percentage <- (var_imp_df$Importance / sum(var_imp_df$Importance)) * 100

ggplot(var_imp_df, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  geom_text(aes(label = paste0(round(Percentage, 1), "%")), hjust = -0.2) + 
  coord_flip() +  
  labs(title = "Variable Importance", x = "Variables", y = "Importance") +
  theme_minimal() +
  theme(plot.margin = unit(c(1, 1, 1, 2), "cm")) 



#-------------------------------------------------------Random Forests-----------------------------------------
dt_rf <- dt_filtered
colnames(dt_rf)
dt_rf$log_los <- NULL
#------------train-test split
set.seed(1)
train <- sample.split(Y=dt_rf$Length.of.Stay, SplitRatio = 0.7)
trainset <- dt_rf[train == T]
testset <- dt_rf[train == F]
#--rf model
RF.all <- randomForest(Length.of.Stay ~ . , data=trainset, importance = T)
print(RF.all ) #ntree=500,mtry=5

RF.yhat <- predict(RF.all, newdata = testset)
RMSE.test.RF <- sqrt(mean((testset$Length.of.Stay - RF.yhat)^2))
RMSE.test.RF 
# 5.776239

# ----------optimization：fine-tuning
B <- c(25, 25, 25, 100, 100, 100, 500, 500, 500)
# m:Num of X variables in dataset
m <- ncol(dt_rf)-1
RSF <- rep.int(c(1, floor(m/3), m), times=3)
OOB.error <- seq(1:9)

set.seed(1)  # for Bootstrap sampling & RSF selection.
for (i in 1:length(B)) {
  m.RF <- randomForest(Length.of.Stay ~ . , data = trainset,
                       mtry = RSF[i],
                       ntree = B[i],
                       na.action = na.omit)
  OOB.error[i] <- m.RF$mse[m.RF$ntree]
}

results <- data.frame(B, RSF, OOB.error)
print(results)
# get the best parameter:B=500 ,RSF=5 ,OOB.error=35.36801(namely RF.all)
print(RF.all )
#check the variable importance
var.impt <- importance(RF.all )
varImpPlot(RF.all , type = 1)
varImpPlot(RF.all, type = 2)


##improvement: delete the outliers of length of stay (using IQR)
# calculate the upper bound of outliers, which is Q3 + 1.5*iqr
Q3 <- quantile(dt_filtered$Length.of.Stay, 0.75)
iqr <- IQR(dt_filtered$Length.of.Stay)
upper_bound <- Q3 + 1.5 * iqr #20.5
# filter data
dt_filtered <- dt_filtered[Length.of.Stay<20.5,]


#------------------------- improve Linear regression-----------------------------------
dt_lm <- dt_filtered
colnames(dt_lm)
#------------train-test split
set.seed(1)
train <- sample.split(Y=dt_lm$log_los, SplitRatio = 0.7)
trainset <- dt_lm[train == T]
testset <- dt_lm[train == F]
#-------------step regression
lr <- step(lm(log_los ~ Hospital.Service.Area + Age.Group + Gender + Race + Ethnicity +
                Type.of.Admission + Patient.Disposition + APR.DRG.Code +
                APR.Severity.of.Illness.Code + APR.Risk.of.Mortality + 
                APR.Medical.Surgical.Description + Payment.Typology.1 + 
                Payment.Typology.2 + Payment.Typology.3 + Emergency.Department.Indicator, data = trainset)) 
##use step()to do stepforward linear regression 
summary(lr) #Adjusted R-squared:  0.2969 ; p-value: < 2.2e-16

# calculate error rate:
lr_log.yhat <- predict(lr, newdata = testset)
lr.yhat <- exp(lr_log.yhat)
RMSE.test.lr <- sqrt(mean((testset$Length.of.Stay-lr.yhat)^2))
RMSE.test.lr
# 3.858132






