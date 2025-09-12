library(tidyverse)

source("scripts/core_metrics.R")

# Calculate CPOE splits by pressure situation
pressure_adjusted_cpoe <- qb_plays %>%
  mutate(player_id = coalesce(passer_player_id, rusher_player_id),
         player_name = coalesce(passer_player_name, rusher_player_name)) %>%
  group_by(player_name, season) %>%
  summarise(
    dropbacks = n(),
    attempts = sum(pass_attempt, na.rm = TRUE),
    # Clean pocket CPOE
    clean_cpoe = mean(cpoe[qb_pressure == 0], na.rm = TRUE),
    clean_cpoe_plays = sum(qb_pressure == 0, na.rm = TRUE),
    clean_cpoe_attempts = sum(pass_attempt == 1 & qb_pressure == 0, na.rm = TRUE),
    
    # Pressure CPOE
    pressure_cpoe = mean(cpoe[qb_pressure == 1], na.rm = TRUE),
    pressure_cpoe_plays = sum(qb_pressure == 1, na.rm = TRUE),
    pressure_cpoe_attempts = sum(qb_pressure == 1 & pass_attempt == 1, na.rm = TRUE),
    
    # CPOE differential
    cpoe_drop = clean_cpoe - pressure_cpoe,
    
    .groups = 'drop'
  ) %>%
  filter(dropbacks >= 175)

# Analyze how air yards change under pressure
pressure_adjusted_air_yards <- qb_plays %>%
  mutate(player_id = coalesce(passer_player_id, rusher_player_id),
         player_name = coalesce(passer_player_name, rusher_player_name)) %>%
  group_by(player_name, season) %>%
  summarise(
    pass_attempts = sum(pass_attempt == 1, na.rm = TRUE),
    
    # Clean pocket air yards
    clean_air_yards = mean(air_yards[qb_pressure == 0], na.rm = TRUE),
    
    # Pressure air yards
    pressure_air_yards = mean(air_yards[qb_pressure == 1], na.rm = TRUE),
    
    # Air yards differential
    air_yards_drop = clean_air_yards - pressure_air_yards,
    
    .groups = 'drop'
  ) %>%
  filter(pass_attempts >= 150)

##### PRESSURE-ADJ EPA CORRELATIONS #####

final_metrics <- pressure_adjusted_epa %>%
  select(player_name:plus_diff) %>%
  left_join(select(pressure_differential, player_name, season, scramble_rate, pressure_rate, epa_drop, pressure_differential_score),
            by = c("player_name", "season")) %>%
  left_join(select(decision_making, player_name, season, int_rate_diff, fumble_rate_diff, total_turnover_diff),
            by = c("player_name", "season")) %>%
  left_join(select(pressure_adjusted_cpoe, player_name, season, cpoe_drop),
            by = c("player_name", "season")) %>%
  left_join(select(pressure_adjusted_air_yards, player_name, season, air_yards_drop),
            by = c("player_name", "season"))

cor(final_metrics$plus_diff, final_metrics$scramble_rate, use = "complete.obs") # 12%
cor(final_metrics$plus_diff, final_metrics$epa_drop, use = "complete.obs") # -14%
cor(final_metrics$plus_diff, final_metrics$int_rate_diff, use = "complete.obs") # -1%
cor(final_metrics$plus_diff, final_metrics$fumble_rate_diff, use = "complete.obs") # -9%
cor(final_metrics$plus_diff, final_metrics$total_turnover_diff, use = "complete.obs") # -7%
cor(final_metrics$plus_diff, final_metrics$cpoe_drop, use = "complete.obs") # 9%
cor(final_metrics$plus_diff, final_metrics$air_yards_drop, use = "complete.obs") # -4%
