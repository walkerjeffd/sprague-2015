library(tidyverse)

rm(list=ls())

cat(paste0(rep('=', 80), collapse=''), '\n')
cat("Loading detection limits...\n\n")

detection_limits <- list(UPPERDL=c('TP'=0.018,
                                   'PO4'=0.003,
                                   'TN'=0.1,
                                   'NH4'=0.01,
                                   'NO23'=0.01,
                                   'TSS'=1),
                         LOWERDL=c('TP'=0.018,
                                   'PO4'=0.003,
                                   'TN'=0.03,
                                   'NH4'=0.006,
                                   'NO23'=0.008,
                                   'TSS'=1))

detection_limits <- lapply(names(detection_limits), function(limit_name) {
  x <- detection_limits[[limit_name]]
  x <- data.frame(VAR=names(x), LIMIT=unname(x))
  x$LIMIT_NAME <- limit_name
  x
}) %>%
  bind_rows() %>%
  spread(LIMIT_NAME, LIMIT)

cat("Saving detection_limits.Rdata as RDS\n")
saveRDS(detection_limits, file = "detection_limits.Rdata")

cat("\n\n")
