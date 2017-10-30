library(ggplot2)
library(lattice)
dat = read.csv("noncol_data.csv")
dat$Rank.Type =  as.factor(dat$Rank.Type)
op_dat <- read_csv("~/Dev/nemo-pmbs/op_dat.csv")
ggplot(data=dat,mapping=aes(x = Run.Name, y=Mean, color=Rank.Type)) + 
  geom_pointrange(mapping=aes(ymin=Min,ymax=Max,shape=Run.Name)) + 
  geom_errorbar(mapping=aes(ymin=Min,ymax=Max))+ 
  facet_wrap(~ Metric,  scales='free_y')  + 
  scale_shape_manual(values=0:12) +
  theme(axis.text.x=element_text(angle=-90))
