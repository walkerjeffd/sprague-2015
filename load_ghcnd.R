library(dplyr)
library(lubridate)
library(ggplot2)
theme_set(theme_bw())

DATA_DIR <- getOption('UKL_DATA')

# load data ----
ghcnd <- read.csv(file.path(DATA_DIR, 'sprague', 'ghcnd', 'ghcnd_sprague.csv'), stringsAsFactors=FALSE, na.strings='-9999') %>%
  select(STATION, STATION_NAME, ELEVATION, LATITUDE, LONGITUDE, DATE, TMIN, TMAX, PRCP, SNOW) %>%
  mutate(TMIN=TMIN/10, # degC
         TMAX=TMAX/10, # degC
         PRCP=PRCP/10) # mm/day
ghcnd <- mutate(ghcnd,
                DATE=ymd(DATE),
                MONTH=month(DATE),
                WYEAR=fluxr::wyear(DATE))
stn.ghcnd <- select(ghcnd, STATION, STATION_NAME, ELEVATION, LATITUDE, LONGITUDE) %>% unique

# plots ----
ggplot(ghcnd, aes(DATE, PRCP)) +
  geom_point(size=1) +
  facet_wrap(~STATION_NAME) +
  labs(x="Date", y="Precip (mm/day)",
       title="GHCND Daily Precipitation")

group_by(ghcnd, STATION_NAME, WYEAR) %>%
  summarise(N=sum(!is.na(PRCP)),
            N_NA=sum(is.na(PRCP)),
            PRCP=sum(PRCP, na.rm=TRUE)) %>%
  ggplot(aes(factor(WYEAR), N)) +
  geom_bar(stat='identity') +
  facet_wrap(~STATION_NAME) +
  labs(x="Water Year", y="Number of Daily Observations",
       title="GHCND Daily Observation Count by Water Year")

# save ----
save(ghcnd, stn.ghcnd, file='ghcnd.Rdata')