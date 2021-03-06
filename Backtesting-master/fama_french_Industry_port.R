# https://systematicinvestor.wordpress.com/2011/12/13/backtesting-minimum-variance-portfolios/
# Homework
#==============================================================================================
#1. Download 10 industry portfolio returns (average value-weighted monthly returns) from 
#   Fama  French data library (http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html)
#2. Compute equal weight portfolio returns EACH month starting from 2000/01 to 2020/03. 
#   Denote this strategy as the Benchmark portfolio and create its backtesting report using SIT. 
#3. Compute  MVP portfolio returns by rebalancing EACH month starting from 2000/01 to 2020/03. 
#   Use in-sample data range of 36 months to compute covariance matrix. Denote this strategy 
#   as the MVP portfolio and create its backtesting report using SIT.
#4. Plot both strategies side by side and compare their performance and comment.



rm(list = ls())
con = gzcon(url('https://github.com/systematicinvestor/SIT/raw/master/sit.gz', 'rb'))
source(con)
close(con)

#****************************************************************** 
library(pacman)
p_load(quantmod, quadprog, lpSolve)
#
industry10 <- read.table("10_Industry_Portfolios_Wout_Div.txt", header = TRUE)
date <- seq(as.Date("1926-08-01"), length=1126, by="1 month") - 1
industry10 <- xts(coredata(industry10[, -1])/100, order.by = date)
head(industry10)
# convert into prices
industry.price <- cumprod(industry10+1)*100
head(industry.price)
tail(industry.price)
#
industry.price.sample <- industry.price['199912/202003']
#
models.tw<-list()
# set up inputs of SIT bt function
# Required inputs for SIT:
# 1. create data variable, data$weight, data$prices and data$execution.price
# 2. data$symbolnames
data <- new.env()
data$prices = data$weight = data$execution.price = industry.price.sample
data$execution.price[] <- NA
data$symbolnames <- colnames(data$prices)
prices = data$prices   
n = ncol(prices)

# Equal Weight 1/N Benchmark
data$weight = ntop(prices, n)
head(data$weight)
names(data)
# bt.run() is backtesting function
models.tw$equal.weight <- bt.run(data, trade.summary = T)
names(models.tw$equal.weight)
#
#capital = 100000
#data$weight[] = (capital / prices) * data$weight
#equal.weight = bt.run(data, type='share')
#head(equal.weight$ret)
#
bt.detail.summary(models.tw$equal.weight)
plotbt.transition.map(models.tw$equal.weight$weight)
plotbt.monthly.table(models.tw$equal.weight$equity)
strategy.performance.snapshoot(models.tw, T)
#=================================================================
# MVP portfolio
#=================================================================
# reset sample range
industry.price.sample <- industry.price['199701/202003']
# industry10.price.sample <- industry10['199701/202003']
# Reset inputs to SIT bt function
data$prices = data$weight = data$execution.price = industry.price.sample
#data$prices <- industry.price.sample
#data$weight <- industry.price.sample
#data$execution.price <- industry.price.sample
data$execution.price[] <- NA
prices <- data$prices

#*****************************************************************
# Create Constraints
#*****************************************************************
constraints = new.constraints(n, lb = -Inf, ub = +Inf)

# SUM x.i = 1
constraints = add.constraints(rep(1, n), 1, type = '=', constraints)        

ret = prices / mlag(prices) - 1
weight = coredata(prices)
weight[] = NA

# i = 36
# i = 245
for (i in 36:dim(weight)[1]) {
  # using 36 historical monthly returns
  hist = ret[ (i- 36 +1):i, ]
  hist = na.omit(hist)
  # create historical input assumptions
  ia = create.historical.ia(hist, 12)
  s0 = apply(coredata(hist),2, sd)     
  ia$cov = cor(coredata(hist), use='complete.obs',method='kendall') * (s0 %*% t(s0))
  # use min.risk.portfolio() to compute MVP weights
  weight[i,] = min.risk.portfolio(ia, constraints)
}

# apply(weight, 1, sum)

data$weight[] = weight     
#capital = 100000
#data$weight[] = (capital / prices) * data$weight
models.tw$min.var.monthly = bt.run(data)
# to verify the default do.lag  = 1 day
# sum(as.numeric(weight[36,])*as.numeric(ret[37,]))
# min.var.monthly$ret[37, ]
plotbt.custom.report.part1(models.tw$min.var.monthly, models.tw$equal.weight)
#
layout(1:2)
plotbt.transition.map(models.tw$min.var.monthly$weight)
legend('topright', legend = 'min.var.monthly', bty = 'n')
plotbt.transition.map(models.tw$equal.weight$weight)
legend('topright', legend = 'equal weight', bty = 'n')

strategy.performance.snapshoot(models.tw, T)
models.tw <- rev(models.tw)
plotbt.custom.report(models.tw)

bt.detail.summary(models.tw$min.var.monthly)
plotbt.strategy.sidebyside(models.tw, return.table=T, make.plot = F)
#strategy.performance.snapshoot(models.tw, T)

# 
# download 8 industry index from TEJ from 2000-2020
# construct equal weight and mvp portfolio 
# compare the performance of two strategies

# Q1. Construct portfolios based on monthly returns 
#     (using 36-month historical returns) 
# Q2. Construct portfolios based on weekly returns
# Q3. Construction portfolios based on single index model
# Q4. Construct portfolios based on Fama-French three factor model
# PCA models
# many models garch, var, cvar...




