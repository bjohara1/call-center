# Import Packages
library(magrittr)
library(readr)
library(ggplot2)
library(rpart)
library(rpart.plot)
library(ROCR)
library(plyr)
library(dplyr)
library(scales)
library(knitr)
library(gridExtra)
library(grid)
library(readr)
library(lubridate)

#Read data - Needs to be modified by Smart Team
smart <- read_csv("C:/Users/bo762818/OneDrive - GSK/Desktop/dispositions_nov.csv")

#Convert data types
smart=as.data.frame(smart)
smart$fromLocalTime <- as.POSIXct(smart$fromLocalTime,format="%m/%d/%Y %H:%M")
smart$propertyID=as.numeric(smart$propertyID)
smart$UptodateTarget= ifelse(smart$IsUpToDate=="TRUE",1,0)

#Feature creation
#followupToNow needs to be modified when new data comes
smart=smart %>% 
  arrange(propertyID, fromLocalTime) %>%
  mutate(followup_days = ifelse(propertyID == lag(propertyID), (fromLocalTime - lag(fromLocalTime))/24/3600, 0)) %>% 
  mutate(fromLocalTimeUTC = fromLocalTime + case_when(
    state %in% c("WA","OR","CA","NV")~7*60*60,
    state %in% c("MT","ID","WY","UT","CO","AZ","NM")~6*60*60,
    state %in% c("ND","SD","NE","KS","OK","TX","MN","IA","MO","AR","LA","WI","IL","TN","MS","AL")~5*60*60,
    state %in% c("MI","IN","OH","PA","NY","VT","ME","NH","MA","RI","CT","KY","NJ","DE","MD","WV","VA","NC","SC","GA","FL","DC")~4*60*60,
    state %in% c("AK")~8*60*60,
    state %in% c("HI")~9*60*60, 
    TRUE ~ NA_real_)) %>%
  mutate(followupToNow = ifelse(propertyID == lead(propertyID), 0, (now()-fromLocalTimeUTC))/24/3600) %>%
  mutate(hourUTC1 = lubridate::hour(fromLocalTime) + case_when(
    state %in% c("WA","OR","CA","NV")~7,
    state %in% c("MT","ID","WY","UT","CO","AZ","NM")~6,
    state %in% c("ND","SD","NE","KS","OK","TX","MN","IA","MO","AR","LA","WI","IL","TN","MS","AL")~5,
    state %in% c("MI","IN","OH","PA","NY","VT","ME","NH","MA","RI","CT","KY","NJ","DE","MD","WV","VA","NC","SC","GA","FL","DC")~4,
    state %in% c("AK")~8,
    state %in% c("HI")~9,
    TRUE ~ NA_real_)) %>%
  group_by(propertyID, hourUTC1) %>% mutate(Probability = mean(UptodateTarget)) %>%
  mutate(model = ifelse(Probability>0.779, "YES", 
                        ifelse(Probability<0.47, "NO", 
                               ifelse(followupToNow>29.9, "NO",
                                      ifelse(followupToNow>0.0017,"YES",
                                             ifelse(Probability<0.59,"NO","YES"))))))
#Retargeting
smart=as.data.frame(smart)
zeroProb = smart %>% 
  dplyr::filter(Probability == 0) %>% 
  dplyr::group_by(propertyID) %>% 
  dplyr::summarise(total = n())

bestTimesList = lapply(1:nrow(zeroProb),function(i){
  limit = zeroProb$total[i]
  
  bestTime = smart %>% 
    dplyr::filter(propertyID == zeroProb$propertyID[i]) %>% 
    dplyr::arrange(desc(Probability)) %>% 
    dplyr::slice(1:limit)
  
  return(bestTime)
})

bestTimeDf = bind_rows(bestTimesList)
smart1 <- filter(smart, Probability > 0)
total <- rbind(smart1, bestTimeDf)
total = total %>% 
  dplyr::arrange(hourUTC1, -Probability)

#Output
smartdf=as.data.frame(total)
call1=smartdf %>%
  # distinct(propertyID, .keep_all=TRUE) %>%
  # filter(Probability > 0.25) %>%
  # filter(followup_days > 20.99) %>%
  arrange(hourUTC1,-Probability, -followupToNow)
call1$Priority1 <- seq.int(nrow(call1))
call1=call1  %>%
  mutate(Priority = ifelse(model=="NO", -1, Priority1))
call=call1  %>%  select(23,1,19)

#File
call=as.data.frame(call)
write.csv(call,'Queue_updated.csv')


