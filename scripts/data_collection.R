library(tidyverse)
library(nflreadr)
library(nflfastR)

# Load play-by-play data
pbp_data <- load_pbp(seasons = 2018:2025)
write.csv(pbp_data, file = "data/raw/pbp_data.csv", row.names = FALSE)

# Load NGS data which contains pressure variables
ngs_data <- load_nextgen_stats(
  seasons = 2018:2025,
  stat_type = "passing"
)
write.csv(ngs_data, file = "data/raw/ngs_data.csv", row.names = FALSE)

# Filter for passing attempts AND QB scrambles
qb_plays <- pbp_data %>%
  filter(
    season_type == "REG",
    (play_type == "pass" | (play_type == "run" & qb_scramble == 1)),
    qb_kneel == 0,
    qb_spike == 0
  ) %>%
  mutate(qb_pressure = ifelse(qb_hit == 1 | sack == 1, 1, 0))
write.csv(qb_plays, file = "data/processed/qb_plays.csv", row.names = FALSE)
