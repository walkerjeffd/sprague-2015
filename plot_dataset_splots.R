library(lubridate)
library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)
theme_set(theme_bw())
library(GGally)

load('kt_sprague.Rdata')
source('functions.R')

# load data ----
wq.raw <- wq.kt_sprague[['RAW']] %>%
  mutate(SITE_NAME=ordered(SITE_NAME, levels=levels(stn.kt_sprague$SITE_NAME)))

wq <- filter(wq.raw, !FLAGGED, QAQC %in% c('PASS', 'RPD')) %>%
  mutate(VAR_UNITS=paste0(VAR, ' (', UNITS, ')')) %>%
  filter(VAR %in% c('FLOW', 'COND', 'TP', 'PO4', 'TN', 'NO23', 'NH4', 'TSS')) %>%
  mutate(VAR=ordered(VAR, levels=c('FLOW', 'COND', 'TP', 'PO4', 'TN', 'NH4', 'NO23', 'TSS'))) %>%
  arrange(VAR, SITE_NAME, DATE) %>%
  mutate(VAR_UNITS=ordered(VAR_UNITS, levels=unique(VAR_UNITS))) %>%
  select(DATE, SITE, SITE_NAME, VAR, VAR_UNITS, VALUE)
  
idx <- which(wq$VAR == 'COND' & log10(wq$VALUE) < 1.2)
wq <- wq[-idx, ]

idx <- which(wq$VAR == 'COND' & log10(wq$VALUE) > 2.5)
wq <- wq[-idx, ]

variable <- 'TP'
site <- 'Power'

pdf(file.path('pdf', 'dataset-scatterplots-variable.pdf'), width=11, height=8.5)
for (site in levels(wq$SITE_NAME)) {
  cat(site, '\n')
  p <- wq %>%
    mutate(VALUE=log10(VALUE)) %>%
    select(-VAR_UNITS) %>%
    spread(VAR, VALUE) %>%
    filter(SITE_NAME==site) %>%
    select(-DATE, -SITE, -SITE_NAME) %>%
    #   ggpairs(upper=list(continuous = "points", combo = "dot")) +
    ggpairs(upper=list(continuous="points", params=c(size=1)),
            lower=list(continuous="points", params=c(size=1)),
            title=paste0('Variable Comparison Plots (Values are Log10 Transformed and Exclude Outliers), Site: ', site),
            params=list(labelSize=6)) +
    theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5))
  print(p, left=0.5, bottom=0.5)
}
dev.off()

pdf(file.path('pdf', 'dataset-scatterplots-site.pdf'), width=11, height=8.5)
for (variable in levels(wq$VAR)) {
  cat(variable, '\n')
  p <- wq %>%
    filter(VAR==variable) %>%
    mutate(YEAR=year(DATE),
           WEEK=floor(week(DATE)/2),
           VALUE=log10(VALUE)) %>%
    group_by(SITE_NAME, YEAR, WEEK) %>%
    summarise(VALUE=median(VALUE)) %>%
    spread(SITE_NAME, VALUE) %>%
    select(-YEAR, -WEEK) %>%
    #   ggpairs(upper=list(continuous = "points", combo = "dot")) +
    ggpairs(upper=list(continuous="points", params=c(size=1)),
            lower=list(continuous="points", params=c(size=1)),
            title=paste0('Site Comparison Plots (Values are Log10 Transformed and Exclude Outliers), Variable: ', variable)) +
    theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5))
  print(p, left=0.5, bottom=0.5)
  Sys.sleep(1)
}
dev.off()

log_y <- scale_y_log10(breaks=log_breaks(seq(1, 9), 10^seq(-3, 3)),
                       labels=log_labels(c(1, 5), 10^seq(-3, 3)))

pdf(file.path("pdf", "dataset-seasonal-patterns.pdf"), width=11, height=8.5)
p <- mutate(wq, 
       WDAY=water_day(DATE),
       WDAY_DATE=ymd("2000-10-01") + days(WDAY)) %>%
  ggplot(aes(WDAY_DATE, VALUE)) +
  geom_point(size=0.7) +
  geom_smooth(method="loess", se=FALSE, span=0.5) +  
  scale_x_datetime(label=scales::date_format("%b %d")) +
  facet_grid(VAR_UNITS~SITE_NAME, scales='free_y') +
  theme(axis.text.y=element_text(size=6),
        axis.text.x=element_text(angle=90, hjust=1, vjust=0.5, size=6),
        panel.grid.minor.y=element_blank(),
        strip.text=element_text(size=8))
p + log_y +
  labs(x="Water Year Day", y="Value") +
  ggtitle("Seasonal Patterns by Site and Variable")
dev.off()