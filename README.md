# call-center
# structured data, logistic classification
# Call centers calling on a random schedule. I gave agents a daily list of most likely to update records (meaning moving forward in sales cycle). 
# With disposition as target variable, I found the best predictor variables to be - followup time between last call, call duration, time of day.
# I had to transform times/locations of customers, add features in terms of followup time, etc
# and the model performed well (92% vs 50% random) and generalized well (classified 55k out of 60k records, 92%)
# This led to a much higher success rate of calls (40% vs 10%), faster sales cycles (27 days to 16 days), and more efficient selling during covid
# Also led to discovering some descriptive analyses which helped the above - keep call duration times in sweet spot, after call time above 10 minutes is worthless
# , find sweet spot of call back frequency and time between etc
