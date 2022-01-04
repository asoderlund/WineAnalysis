# Stat515-003 Final Project
# Alyssa Soderlund
# 12/8/21

# Import libraries

library(ggplot2)
source('hw.R')
library(leaps)
library(lattice)
library(grid)
library(hexbin)
library(randomForest)
library(rpart)
library(rpart.plot)
library(plotly)
library(caTools)
library(caret)
library(effects)
library(cluster)


# Read in data
redData <- read.csv("Stat515/Final/winequality-red.csv")

# Data Summary
summary(redData)

# Quality score can be from 1-10 but the lowest given is a 3 
# and the highest is an 8
# Missing data- no
sum(is.na(redData))



# EDA

# We can see from the histograms that most scores are between 4 and 6 
ggplot(data= redData, aes(quality)) + 
    geom_histogram(breaks= seq(2, 8, by=1), col="black", fill="cyan") + 
    labs(title= "Histogram for Quality of Red Wines") + hw

# Scatterplot matrix shows variables most correlated with quality
# alcohol, volatile acidity, sulphates, citric acid, density, and sulfur dioxide 
# are the parameters that have the strongest correlations with quality
splom(redData, as.matrix = TRUE,
      xlab = '',main = "Red Wine Data",
      pscale = 0, varname.col = "red",
      varname.cex = 0.56, varname.font = 2,
      axis.text.cex = 0.4, axis.text.col = "red",
      axis.text.font = 2, axis.line.tck = .5,
      panel = function(x,y,...) {
          panel.grid(h = -1,v = -1,...)
          panel.hexbinplot(x,y,xbins = 12,...,
                           border = gray(.7),
                           trans = function(x)x^1)
          panel.loess(x , y, ...,
                      lwd = 2,col = 'purple')},
      diag.panel = function(x, ...){
          yrng <- current.panel.limits()$ylim
          d <- density(x, na.rm = TRUE)
          d$y <- with(d, yrng[1] + 0.95 * diff(yrng) * y / max(y) )
          panel.lines(d,col = gray(.8),lwd = 2)
          diag.panel.splom(x, ...) })


# Take closer look at alcohol/volatile acidity/sulphates and quality
# Did not include box plots to keep under page limit
# redData %>%
#   plot_ly(x = ~quality, y = ~alcohol) %>%
#   add_boxplot() %>%
#   layout(title = "Boxplots of Alcohol for Each Quality Score",
#          xaxis = list(title = 'Quality Score'),
#          yaxis = list(title = 'Alcohol (vol.%)'))
# 
# redData %>%
#   plot_ly(x = ~quality, y = ~volatile.acidity) %>%
#   add_boxplot()%>%
#   layout(title = "Boxplots of Volatile Acidity for Each Quality Score",
#          xaxis = list(title = 'Quality Score'),
#          yaxis = list(title = 'Volatile Acidity (g(acetic acid)/dm<sup>3</sup>)'))
# 
# redData %>%
#   plot_ly(x = ~quality, y = ~sulphates) %>%
#   add_boxplot()%>%
#   layout(title = "Boxplots of Sulphates for Each Quality Score",
#          xaxis = list(title = 'Quality Score'),
#          yaxis = list(title = 'Sulphates (g(potassium sulphate)/dm<sup>3</sup>)'))

redData %>% 
  plot_ly(x=~alcohol,y=~volatile.acidity,z= ~sulphates, color=~quality, 
          hoverinfo = 'text',
          text = ~paste('Quality:', quality,
                        '<br>Alcohol:', alcohol,
                        '<br>Volatile Acidity:', volatile.acidity,
                        '<br>Sulphates:', sulphates)) %>% 
  add_markers() %>%
  layout(title = "Wine Quality: Sulphates, Volatile Acidity, and Alcohol",
         scene = list(xaxis = list(title = 'Alcohol (vol.%)'),
                      yaxis = list(title = 'Volatile Acidity (g(acetic acid)/dm<sup>3</sup>)'),
                      zaxis = list(title = 'Sulphates (g(potassium sulphate)/dm<sup>3</sup>)')))




# VARIABLE SELECTION

# Subset selection: regular, forwards and backwards stepwise selection
regfit.full=regsubsets (quality~.,redData[,1:12],nvmax=10)
reg.summary=summary(regfit.full)
reg.summary
plot(regfit.full, main="Best Subset Selection for Indpendent Variables", scale="r2",
     labels=c("Intercept","Fixed Acidity","Volatile Acidity","Citric Acid","Residual Sugar",
              "Chlorides","Free S.D.","Total S.D.","Density","pH","Sulphates","Alcohol"))

# how many to pick?
par(mfrow=c(2,2))
plot(reg.summary$rss ,xlab="Number of Variables ",ylab="RSS",
     type="l", main="Variable Subset Selection: RSS")
plot(reg.summary$adjr2 ,xlab="Number of Variables ",
     ylab="Adjusted RSq",type="l", main="Variable Subset Selection: Adjusted RSq")
# let's choose 6 variables

regfit.fwd=regsubsets (quality???.,data=redData[,1:12] , nvmax=6,
                       method ="forward")
summary (regfit.fwd)

regfit.bwd=regsubsets (quality???.,data=redData[,1:12] , nvmax=6,
                       method ="backward")
summary (regfit.bwd)

# all 3 give same results
# top 6: va, ch, total sd, ph, sulphates, alcohol





# CLASSIFICATION SECTION

# create variable for good/bad wine (quality 6 or greater is good)
redData$isGood<-ifelse(redData$quality>=6,"Good","Bad")

# train/test split
set.seed(1)
sample = sample.split(redData$isGood, SplitRatio = .75)
train = subset(redData, sample == TRUE)
test  = subset(redData, sample == FALSE)

# Decision tree 
rtree  = rpart( isGood ~volatile.acidity+chlorides+total.sulfur.dioxide+pH+sulphates+alcohol, data=train)
rpart.plot( rtree, faclen=12, extra=1, digits=3, main="Classification Tree: Good or Bad Wine")
summary(rtree)

# use decision tree to make prediction
rtreeTest <- predict(rtree, newdata = test, type='class')
confusionMatrix(factor(rtreeTest),factor(test$isGood))
# accuracy is 73%




# Random forest
redwineRF<-randomForest(factor(isGood)~.-quality,data=train)
redwineRF
# oob error is 20%
importance(redwineRF)

varImpPlot(redwineRF, main=" \n Variable Importance Red Wine",
           labels=c("Residual Sugar","Free Sulfur Dioxide","Fixed Acidity",
                    "Citric Acid","pH","Chlorides","Density",
                    "Total Sulfur Dioxide","Volatile Acidity","Sulphates","Alcohol"))

yhat = predict(redwineRF, newdata = test)
confusionMatrix(factor(yhat), factor(test$isGood))
# accuracy is 84% (higher with all variables instead of subset)





# Logistic Regression for classification

# log transform skewed variables
logRedData <- redData %>% mutate(residual.sugar = log(residual.sugar),
                    chlorides = log(chlorides),
                    free.sulfur.dioxide = log1p(free.sulfur.dioxide),
                    total.sulfur.dioxide = log1p(total.sulfur.dioxide),
                    sulphates = log(sulphates))

# Check histograms
# logRedData %>% ggplot(aes(x=residual.sugar)) + geom_histogram(bins=25)
# logRedData %>% ggplot(aes(x=chlorides)) + geom_histogram(bins=25)
# logRedData %>% ggplot(aes(x=free.sulfur.dioxide)) + geom_histogram(bins=25)
# logRedData %>% ggplot(aes(x=total.sulfur.dioxide)) + geom_histogram(bins=25)
# logRedData %>% ggplot(aes(x=sulphates)) + geom_histogram(bins=25)


# add binary variable, quality score 6 or higher is good
logRedData$isGood<-ifelse(logRedData$quality>=6,1,0)

# train test split for log transformed data
set.seed(1)
sample = sample.split(logRedData, SplitRatio = .75)
logtrain = subset(logRedData, sample == TRUE)
logtest  = subset(logRedData, sample == FALSE)

# logistic regression model creation using training set
trainLM <- glm(isGood ~volatile.acidity+chlorides+total.sulfur.dioxide+pH+sulphates+alcohol, data = logtrain, family = binomial(link="logit"))

# Predict on test set
logtest$yPredProbs <- predict(trainLM, logtest, type="response")
logtest$yPred <- ifelse(logtest$yPredProbs > 0.5, 1, 0)

summary(trainLM)

confusionMatrix(factor(logtest$yPred), factor(logtest$isGood), positive='1')
#accuracy is 75%

# plot effects for each variable
plot(allEffects(trainLM))



# CLUSTERING- will it cluster by good and bad wines?

wineCluster <- kmeans(redData[,1:11], 2, nstart = 20)

wineCluster
table(wineCluster$cluster, redData$isGood)

d = dist(redData)
clusplot(d, diss=TRUE, wineCluster$cluster, color=TRUE, shade = TRUE, lines=0,
         main="K-Means Clusters (k=2)")














