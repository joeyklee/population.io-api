rm(list=ls())

#load libraries
library(splines)# interpolating using splines - methods (need to read this to understand exactly how interpolation is done)
library(car)#general functions 

#setwd("/Users/florianhuber/Dropbox/uni/phd/Samir World Bank/BigData") #set working directory
setwd("c:/dropbox/Samir World Bank/BigData") #set working directory

# 1. Interpolate between calendar days 
# For e.g. interpolate between 1 year old in 1st July 2010 and 1 year old in 1st July 2011 
#  to get 1 year olds in 2nd July 2010 to 30th June 2011
 
# 2. Interploate the daily population of 1 years old to 365 days
# For e.g. Interpolate between 1 years old and 2 years old, assigning the 1 years old to 365+183 days of exact age and so on 

#UN population by age in single years and sex annually during 1950-2100 
pop <- read.csv("WPP2012_INT_F3_Population_By_Sex_Annual_Single_100_Medium.csv")
#recoding a case as "/" is not allowed 
pop$Location <- recode(pop$Location, "'Australia/New Zealand' ='Australia and New Zealand'")
#getting the list of country/regions
lstcntry <- as.vector(unique(pop$Location))


#Annual data are for the 1st of JUly, getting the dates
dts <- as.Date(paste(unique(pop$Time),7,1,sep="/"),"%Y/%m/%d") # Y is for 2050 and y is for 50
date2 <- as.numeric(as.Date(paste(unique(pop$Time),7,1,sep="/"),"%Y/%m/%d") )#Reference date is 1970/01/01 (1)
#this is the range of days, 1st of Jan 1950 to 31st dec 2100
xout = range(date2) + c(-as.numeric(dts[1]-as.Date("1950/1/1","%Y/%m/%d")), as.numeric(as.Date("2100/12/31","%Y/%m/%d")-dts[151]))


#function that extrapolates the 1st July data to each calender day
doitall <- function (CNTRY, iSEX, RESULT) { #for given country, sex, and RESULT = 0 means not to save in the file
  SEX = SEXnames[iSEX]
  pop1 <-  subset(pop,Location == CNTRY,select= c("Time", "Age", SEX))#a population is selected from UN
  dateInterp <- function (iage) { #define function that interpolates between dates for each age
    popi <- as.vector(as.matrix(subset(pop1, Age==iage, select=SEX))) #select particular age
    ispl <- interpSpline(popi~date2,bSpline = TRUE) #spline interpolation function from R package
    predict(ispl,seq(xout[1],xout[2],by=1))$y #interpolated values for all theperiods
  }
  result1 <- sapply(X=c(0:100),FUN = dateInterp, simplify=TRUE, USE.NAMES=TRUE) #loop for all ages
  result1 <- as.data.frame(result1) #save it in data frame format
  names(result1)<- paste("age",0:100, sep="_") #column names
  result1 <- transform(result1, date1 = as.Date(seq(xout[1],xout[2],by=1),origin = "1970-01-01"))
  if(RESULT == 0) { 
    write.csv(result1, paste(CNTRY,SEX,".CSV",sep=""),row.names=F) #save the data
  } else {
    result1
  }
}

#sex names as in the data "pop"
SEXnames <- names(pop)[grep("Pop",names(pop))]
#AGE in days refering to the annual data - we assume that the average age of one years old is 1 years and 183 days
age3 <- c(0:99)*365+183
#this is the range of days (age)
ageout = seq(0,36500)


#function that interpolates age in days
dayInterpA <- function (iDate) {
  #age 0 to 99
  popi <- as.vector(as.matrix(subset(pop2, date1==iDate,select=-c(date1,age_100))))
  ispl2 <- interpSpline((popi/365)~age3,bSpline = TRUE) #THIS STEP IS IMPORTANT TO CHECK THAT POPI MATCHES WITH AGE3
  x <- predict(ispl2,ageout)
  data.frame(AGE=x$x,POP=x$y)
}


#my rank by age: What will be my rank when I am aged xxxx days
yourRANKbyAge <- function (DoB,iAge) {
  DoB  <- as.Date(DoB,"%Y/%m/%d")
  DATE = as.numeric(DoB) + iAge #date in numeric
  X <- dayInterpA(DATE) #DATE can be either numeric or in date formate ... reference is 1970-1-1  
  RANK <- mean(cumsum(X$POP)[c(match(iAge, X$AGE)-1,match(iAge, X$AGE))])
  RANK
}
#my rank by date: What will be my rank on particular day
yourRANKbyDate <- function (DoB,DATE) {
  DoB  = as.Date(DoB,"%Y/%m/%d")
  DATE  = as.Date(DATE,"%Y/%m/%d")
  iAge = as.numeric(DATE - DoB)
  X <- dayInterpA(DATE) 
  RANK <- mean(cumsum(X$POP)[c(match(iAge, X$AGE)-1,match(iAge, X$AGE))])
  RANK
}
#my rank today: What is my rank today
yourRANKToday <- function (DoB) {
  DoB  <- as.Date(DoB,"%Y/%m/%d")
  iAge <- Sys.Date() - DoB
  X <- dayInterpA(Sys.Date()) 
  RANK <- mean(cumsum(X$POP)[c(match(iAge, X$AGE)-1,match(iAge, X$AGE))])
  RANK
}
#finding the date for specific rank
yourRANKTomorrow <- function(birth,wRank){
  
  final_time <- "2100/1/1"
  length_time <- difftime(final_time,birth)/365
  
  #this is important because we have to make sure that if the given birthdate is too far away in the past,
  #we have to check whether the distance between the birthdate and final time is greater than 100
  l_max <- ifelse(as.numeric(length_time)<100,round(as.numeric(length_time)),100) 
  
  #Does a rough search over the next l_max decades to find the ranks in each decade
  xx <- matrix(0,length(seq(10,l_max,10)),1) #if year of birth > 2010 !
  for (jj in seq(1,length(xx))){
    xx[jj,1] <- yourRANKbyAge(DoB=birth,iAge=jj*3650)
  }
  xx[which(is.na(xx))] <-xx[which(is.na(xx))-1] 
  cc <- all(xx<wRank) 
  if (cc){
    stop("Youre too young!") 
    #Breaks the function if either the birthdate is too late
    #for some rank or the rank is too high for some birthdate
  }
  
  #Now find the interval containing wRank
  Upper_bound <- min(which((xx<wRank)==FALSE))*10
  Lower_bound <- (Upper_bound-10)
  range_2 <- seq(Lower_bound-2,Upper_bound)
  
  xx_ <- matrix(0,length(range_2),2)
  #given that interval, do a yearly interpolation
  for (kk in range_2){
    xx_[(kk-min(range_2)+1),1] <- yourRANKbyAge(DoB=birth,iAge=kk*365)
    xx_[(kk-min(range_2)+1),2] <- kk*365
  }
  
  #now again search for the yearly interval containing wRank
  Upper_bound <- xx_[min(which((xx_[,1]<wRank)==FALSE)),2]
  Lower_bound <- xx_[max(which((xx_[,1]<wRank)==TRUE)),2]
  
  range_3 <- seq(Lower_bound,Upper_bound)  
  
  xx_ <- matrix(0,length(range_3),2)
  
  #From this point on, this stuff is within a year (daily), due to the fact that the evolution of the rank is linear
  #we do linear interpolation to get the exact day faster
  end_point <- range_3[length(range_3)]
  first_point <- range_3[1]
  
  rank_end <- yourRANKbyAge(DoB=birth,iAge=end_point)
  rank_first <- yourRANKbyAge(DoB=birth,iAge=first_point)
  
  #this gives us the age when we reach wRank and the exact date
  final_age <- approx(x=c(rank_first,rank_end),y=c(Lower_bound,Upper_bound),xout=wRank)
  final_date <- as.Date(birth,"%Y/%m/%d")+final_age$y
  
  #now we also want to plot our life-path, so we do spline interpolation for the stuff we calculated in the first step
  # (i.e. the ranks over decades) and interpolate using bSplines.
  xx_interp <- interpSpline(xx~seq(10,l_max,10)*365,bSpline = TRUE) #spline interpolation function from R package
  x_interp <- predict(xx_interp,seq(1,36500,365))
  #find the rank nearest to wRank
  find_r <- which.min(abs(x_interp$y - wRank))
  
  #Then we do the plotting again (Note that if the values are not exact, we have to make a finer interpolation above in the xx_interp part)
  plot(x_interp$y,type="l",xlab="Age",ylab="Rank",col="green") #plot the "life-path"
  #axis(1, at=seq(0,36500-(10*365),10*365)/365, labels=seq(10*365,36500,10*365)/365)
  abline(v=find_r,col="red");abline(h=x_interp$y[[find_r]],col="red") #adds the age when we reach that rank
  grid()
  return(list(exactAGE=round(final_age$y/365,2),AGE=floor(final_age$y/365),DATE=final_date))
}

#e.g.:
#Type your country
CNTRY = "WORLD" # as named in lstcntry
#Type Sex
iSEX = 3 # 1= Males, 2 = Females, and 3 = Both Sexes
#First run the interpolation for the calendar dates in days
pop2 <- doitall(CNTRY=CNTRY,iSEX=3, RESULT = 1) #if RESULT = 0 then this function will save a ~93mb file in csv 
DoB = "1993/12/6"

yourRANKToday(DoB) #my ranking today: 2537976
yourRANKbyAge(DoB=DoB,iAge=as.numeric(Sys.Date()-as.Date(DoB,"%Y/%m/%d"))) #my ranking at today's age: 2537976
yourRANKbyAge(DoB=DoB,iAge=3650) #my ranking when I was 10 years old (3650 days) : 1209918
yourRANKbyDate(DoB,"2001/9/11") #my ranking on 11th Sept 2001 :940947

#e.g. contd..
#when will I become 7 billionth
speRANK <- 7000000 #specific rank
RES <- yourRANKTomorrow(DoB,speRANK)
RES #At the age of XX years old on date YY 
# $exactAGE
# [1] 55.3
# 
# $AGE
# [1] 55
# 
# $DATE
# [1] "2049-03-11"

#read data for life expectancy: male=1,female=2,both=3
life_expectancy_ages <- read.csv("life_expectancy_ages.csv")

# What is the life expectancy on when I reach specific RANK speRANK 
le_exact_age <-  RES$exactAGE #exact age in years in two decimals to reach speRANK:55.3 years
le_age <-  RES$AGE # age in years to reach speRANK: 55 years
le_date <- RES$DATE # date to reach speRANK: 2049-03-11



#For which CNTRY AND SEX DO YOU WANT TO KNOW THE REMAINING LIFE EXPECTANCY AT CERTAIN TIME/AGE
CNTRY1 = "WORLD"
iSEX1 = 3 #male=1,female=2,both=3


rem_le <- function (CNTRY1,iSEX1,le_date) {
  #find beginning of 5 yearly period for the le_date
  le_yr <- as.numeric(substr(le_date,1,4))
  lowest_yr <- floor(le_yr/5)*5 #lower limit of the five yearly period that includes le_yr 

  life_exp_prd <- subset(life_expectancy_ages,region==CNTRY1 & sex==iSEX1 & Begin_prd%in%c(lowest_yr-5,lowest_yr,lowest_yr+5),select=X0:X100) #extract a row corresponding to the time-period

  life_exp_ <- matrix(0,ncol(life_exp_prd),4) # place holder for Agenames and values for three consecutive periods of interest
  life_exp_[,1] <- as.numeric(substr(names(life_exp_prd),2,10)) # Age group starting at and less than the next value: 0, 1, 5, 10 
  life_exp_[,2:4] <- t(as.matrix(life_exp_prd)) #assigning life expectancy values

  xx_interp1 <- interpSpline(life_exp_[,2]~life_exp_[,1],bSpline = TRUE) #spline interpolation function from R package for earlier period: lIfe expectancy ~ AGE
  xx_interp2 <- interpSpline(life_exp_[,3]~life_exp_[,1],bSpline = TRUE) #spline interpolation function from R package period (5 yearly period of interest)
  xx_interp3 <- interpSpline(life_exp_[,4]~life_exp_[,1],bSpline = TRUE) #spline interpolation function from R package next period
  
  x_interp1 <- predict(xx_interp1,le_exact_age) #interpolated value for AGE in earlier 5 yearly period 
  x_interp2 <- predict(xx_interp2,le_exact_age) #interpolated value for AGE in the 5 yearly period of interest
  x_interp3 <- predict(xx_interp3,le_exact_age) #interpolated value for AGE in 5 yearly period after  
  
  life_exp_yr <- matrix(0,3,2) 
  
  #The mid point of period 2010-2015 which is from 1st July 2010 to June 30 of 2015, therefore, the mid point is 1st Jan 2013
  #In the following we turn the year to the date and then to numeric. We will use these to interpolate between periods and then predict the le for exact date
  life_exp_yr[,1]<- as.numeric(as.Date(c(paste(lowest_yr-5+3,1,1,sep="/"),paste(lowest_yr+3,1,1,sep="/"),paste(lowest_yr+5+3,1,1,sep="/")),"%Y/%m/%d"))
  life_exp_yr[,2]<-c(x_interp1$y,x_interp2$y,x_interp3$y)
  
  #plot(life_exp_yr[,2]~life_exp_yr[,1],type="b") #Linear
  spline(life_exp_yr[,2]~life_exp_yr[,1],xout = as.numeric(le_date)) #interpSpline does not work with three values.. so used spline function here which also fits linearly
}

#rem_le(CNTRY1=CNTRY,iSEX1=iSEX,lowest_yr=lowest_yr)
x_interp <- rem_le(CNTRY1=CNTRY,iSEX1=iSEX,le_date=le_date)# continuing the example: 

#Date
as.Date(x_interp$x, origin = "1970-01-01") #2049-03-11
#remaining life expectancy
x_interp$y # 26.24 years

##E.g. contd.
paste("You, born in",DoB, "will reach", paste(speRANK*1000,"th person in ", ifelse(CNTRY=="WORLD","the WORLD",CNTRY), " on",sep=""),
      le_date,"and you will be",le_age," years old. As a",c("Male","Female","")[iSEX1]  ,CNTRY1, "citizen, you will still have", round(x_interp$y,2), "years to live. And your expected date of death is", le_date + x_interp$y*365,sep=" "   )

#[1] "You, born in 1993/12/6 will reach 7e+09th person in the WORLD on 2049-03-11 and you will be 55  years old. As a  WORLD citizen, you will still have 26.24 years to live.
#And your expected date of death is 2075-05-31"

