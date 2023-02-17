library(tidyverse)

# hay1, gtree1, barrel1, hay2, hay3, hay4
dropvals <- c(1, 0, 0, 2, 4, 8)

barn8 <- c(64, 7, 9, 9, 7, 4)
barn7 <- c(67, 7, 8, 9, 7, 2)
barn6 <- c(73, 6, 8, 8, 5, 0)
barn5 <- c(80, 6, 6, 8, 0, 0)

sumvals <- function(probs, num) {
    sum(sample(dropvals, num, prob = probs, replace = TRUE))
}

# 100000 trials with two full lvl8 barns (28 = total items stack)
df <- data.frame(x = replicate(100000, sumvals(barn8, 28) + sumvals(barn8, 28)))
# sumvals(barn8, 4) would be one ad charge on a lvl 8 barn (4 = drops per recharge)
ggplot(df, aes(x)) + geom_density(fill = "grey60")
quantile(df$x, probs = c(.1, .5, .9))
# chance that enough for a lvl 7 hay is dropped
mean(df$x >= 64)

# 100000 trials with full lvl6 and lvl7 barns
df <- data.frame(x = replicate(100000, sumvals(barn6, 24) + sumvals(barn7, 24)))
quantile(df$x, probs = c(.1, .5, .9))
mean(df$x >= 64)
