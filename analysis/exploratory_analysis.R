library(tidyverse)

qb_plays <- read_csv("data/processed/qb_plays.csv")
ngs_data <-read.csv("data/raw/ngs_data.csv")

# Take a look at how 2024 shakes out
qb_2024 <- qb_plays %>%
  mutate(player_id = coalesce(passer_player_id, rusher_player_id),
         player_name = coalesce(passer_player_name, rusher_player_name)) %>%
  inner_join(ngs_data %>% filter(week == 0), 
             by = c("season", "player_id" = "player_gsis_id")) %>%
  group_by(player_id, player_name, season) %>%
  summarise(dropbacks = sum(qb_dropback, na.rm = TRUE),
            pressures = sum(qb_pressure, na.rm = TRUE),
            scrambles = sum(qb_scramble, na.rm = TRUE),
            pressure_rate = mean(qb_pressure, na.rm = TRUE),
            ttt = mean(avg_time_to_throw, na.rm = TRUE)) %>%
  filter(dropbacks >= 175,
         season == 2024) %>%
  arrange(desc(pressure_rate))

print(qb_2024)

# Overall pressure statistics
league_pressure_summary <- qb_plays %>%
  summarise(
    total_dropbacks = n(),
    total_pressure_plays = sum(qb_pressure, na.rm = TRUE),
    league_pressure_rate = mean(qb_pressure, na.rm = TRUE),
    league_pressure_to_sack = sum(sack, na.rm = TRUE) / sum(qb_pressure, na.rm =  TRUE),
    avg_epa_clean = mean(epa[qb_pressure == 0], na.rm = TRUE),
    avg_epa_pressure = mean(epa[qb_pressure == 1], na.rm = TRUE),
    epa_drop = avg_epa_clean - avg_epa_pressure
  )

print(league_pressure_summary)

# Season pressure statistics
season_pressure_summary <- qb_plays %>%
  group_by(season) %>%
  summarise(
    total_weeks = n_distinct(week),
    total_dropbacks = n(),
    total_pressure_plays = sum(qb_pressure, na.rm = TRUE),
    league_pressure_rate = mean(qb_pressure, na.rm = TRUE),
    league_pressure_to_sack = sum(sack, na.rm = TRUE) / sum(qb_pressure, na.rm =  TRUE),
    avg_epa_clean = mean(epa[qb_pressure == 0], na.rm = TRUE),
    avg_epa_pressure = mean(epa[qb_pressure == 1], na.rm = TRUE),
    epa_drop = avg_epa_clean - avg_epa_pressure
  )

print(season_pressure_summary)

# Calculate clean pocket vs pressure EPA for each QB
qb_pressure_performance <- qb_plays %>%
  inner_join(select(season_pressure_summary, season, total_weeks),
             by = "season") %>%
  mutate(player_id = coalesce(passer_player_id, rusher_player_id),
         player_name = coalesce(passer_player_name, rusher_player_name)) %>%
  group_by(player_id, player_name, season, total_weeks) %>%
  summarise(
    dropbacks = n(),
    scrambles = sum(qb_scramble, na.rm = TRUE),
    scramble_rate = scrambles / dropbacks,
    overall_epa = mean(epa, na.rm = TRUE),
    pressure_plays = sum(qb_pressure, na.rm = TRUE),
    pressure_rate = mean(qb_pressure, na.rm = TRUE),
    
    # Clean pocket performance
    clean_epa = mean(epa[qb_pressure == 0], na.rm = TRUE),
    clean_plays = sum(qb_pressure == 0, na.rm = TRUE),
    
    # Pressure performance  
    pressure_epa = mean(epa[qb_pressure == 1], na.rm = TRUE),
    
    # The key metric: EPA drop under pressure
    epa_drop = clean_epa - pressure_epa,
    
    .groups = 'drop'
  ) %>%
  filter(dropbacks >= total_weeks*15/2) %>%  # Your minimum threshold
  arrange(desc(pressure_rate))

print(qb_pressure_performance)

# Check for any concerning patterns
summary(qb_pressure_performance$pressure_rate)
summary(qb_pressure_performance$epa_drop)

# Any QBs with impossibly good pressure performance?
qb_pressure_performance %>%
  filter(pressure_epa > clean_epa) %>%
  select(player_name, season, clean_epa, pressure_epa, pressure_plays)

# Team protection rankings
team_protection <- qb_plays %>%
  filter(!is.na(epa), !is.na(posteam)) %>%
  group_by(posteam, season) %>%
  summarise(
    dropbacks = n(),
    pressure_rate = mean(qb_pressure, na.rm = TRUE),
    clean_epa = mean(epa[qb_pressure == 0], na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(pressure_rate)

print(team_protection)

# Correlation between time to throw and pressure rate
ttt_pressure_corr <- qb_2024 %>%
  select(player_name, pressure_rate, ttt)

# Calculate correlation
cor(ttt_pressure_corr$ttt, ttt_pressure_corr$pressure_rate, use = "complete.obs")
## 22% correlation
## suggests scheme and O-line matter more than just quick release

# Look at extremes
ttt_pressure_corr %>% arrange(ttt) %>% head(5)  # Quickest release
ttt_pressure_corr %>% arrange(desc(ttt)) %>% head(5)  # Slowest release

# Mobility analysis
mobility_analysis <- qb_pressure_performance %>%
  mutate(
    qb_type = ifelse(scramble_rate > 0.08, "Mobile", "Pocket")
  ) %>%
  group_by(qb_type) %>%
  summarise(
    avg_pressure_rate = mean(pressure_rate, na.rm = TRUE),
    avg_clean_epa = mean(clean_epa, na.rm = TRUE),
    avg_pressure_epa = mean(pressure_epa, na.rm = TRUE),
    avg_epa_drop = mean(epa_drop, na.rm = TRUE),
    count = n(),
    .groups = 'drop'
  )

print(mobility_analysis)