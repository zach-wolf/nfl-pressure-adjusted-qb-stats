library(tidyverse)

source("analysis/exploratory_analysis.R")

# First, calculate league averages by season
league_baselines <- qb_plays %>%
  filter(!is.na(epa)) %>%
  group_by(season) %>%
  summarise(
    # Pressure-Adjusted EPA baselines
    league_pressure_rate = mean(qb_pressure, na.rm = TRUE),
    league_clean_epa = mean(epa[qb_pressure == 0], na.rm = TRUE),
    league_pressure_epa = mean(epa[qb_pressure == 1], na.rm = TRUE),
    league_adjusted_epa = league_clean_epa * (1 - league_pressure_rate) + (league_pressure_epa * league_pressure_rate),
    
    # Pressure Differential Score baseline
    league_epa_drop = league_clean_epa - league_pressure_epa,
    
    # Decision-Making baselines
    league_clean_int_rate = sum(interception == 1 & qb_pressure == 0, na.rm = TRUE) / 
      sum(qb_pressure == 0, na.rm = TRUE),
    league_pressure_int_rate = sum(interception == 1 & qb_pressure == 1, na.rm = TRUE) / 
      sum(qb_pressure == 1, na.rm = TRUE),
    league_clean_fumble_rate = sum(fumble_lost == 1 & qb_pressure == 0, na.rm = TRUE) / 
      sum(qb_pressure == 0, na.rm = TRUE),
    league_pressure_fumble_rate = sum(fumble_lost == 1 & qb_pressure == 1, na.rm = TRUE) / 
      sum(qb_pressure == 1, na.rm = TRUE),
    
    # League decision-making differential
    league_decision_diff = (league_pressure_int_rate - league_clean_int_rate) + 
      (league_pressure_fumble_rate - league_clean_fumble_rate),
    .groups = 'drop'
  )

# Then join with QB data and calculate standardized EPA
pressure_adjusted_epa <- qb_pressure_performance %>%
  left_join(league_baselines, by = "season") %>%
  mutate(
    # What would this QB's EPA be if they faced league-average pressure rate?
    adjusted_epa = (clean_epa * (1 - league_pressure_rate)) + 
      (pressure_epa * league_pressure_rate),
    
    # Value gained/lost due to pressure rate differential
    pressure_context_value = adjusted_epa - overall_epa,
    
    # Pressure rate differential from league average
    pressure_rate_diff = pressure_rate - league_pressure_rate
  ) %>%
  group_by(season) %>%
  mutate(
    league_avg_epa = mean(overall_epa, na.rm = TRUE),
    league_sd_epa = sd(overall_epa, na.rm = TRUE),
    league_avg_adj_epa = mean(adjusted_epa, na.rm = TRUE),
    league_sd_adj_epa = sd(adjusted_epa, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  # Plus-stat: 1 std = 33 points, 100 = league average
  # Ex 1: 133 = 1 standard devation better than league average
  # Ex 2: 67 = 1 standard devation worse than league average
  mutate(epa_plus = 100 + ((overall_epa - league_avg_epa) / league_sd_epa) * (100/3),
         adjusted_epa_plus = 100 + ((adjusted_epa - league_avg_adj_epa) / league_sd_adj_epa) * (100/3),
         plus_diff = adjusted_epa_plus - epa_plus) %>%
  select(player_name, season, dropbacks, overall_epa, epa_plus, adjusted_epa, adjusted_epa_plus,
         pressure_context_value, plus_diff, pressure_rate_diff, pressure_rate, league_pressure_rate)

# Calculate how each QB's pressure drop compares to league average
pressure_differential <- qb_pressure_performance %>%
  left_join(league_baselines, by = "season") %>%
  mutate(
    pressure_differential_score = epa_drop / league_epa_drop,  # League average drop
    # Interpretation: >1.0 = worse than average, <1.0 = better than average
    pressure_resistance_grade = case_when(
      pressure_differential_score < 0.7 ~ "Elite",
      pressure_differential_score < 0.9 ~ "Above Average",
      pressure_differential_score < 1.1 ~ "Average", 
      pressure_differential_score < 1.3 ~ "Below Average",
      TRUE ~ "Poor"
    )
  )

# Calculate turnover rates under pressure vs clean pocket
decision_making <- qb_plays %>%
  filter(!is.na(epa)) %>%
  mutate(player_id = coalesce(passer_player_id, rusher_player_id),
         player_name = coalesce(passer_player_name, rusher_player_name)) %>%
  group_by(player_name, season) %>%
  summarise(
    dropbacks = n(),
    # Clean pocket decision making
    clean_int_rate = sum(interception == 1 & qb_pressure == 0, na.rm = TRUE) / 
      sum(qb_pressure == 0, na.rm = TRUE),
    clean_fumble_rate = sum(fumble_lost == 1 & qb_pressure == 0, na.rm = TRUE) / 
      sum(qb_pressure == 0, na.rm = TRUE),
    
    # Pressure decision making  
    pressure_int_rate = sum(interception == 1 & qb_pressure == 1, na.rm = TRUE) / 
      sum(qb_pressure == 1, na.rm = TRUE),
    pressure_fumble_rate = sum(fumble_lost == 1 & qb_pressure == 1, na.rm = TRUE) / 
      sum(qb_pressure == 1, na.rm = TRUE),
    
    # Decision differential
    int_rate_diff = pressure_int_rate - clean_int_rate,
    fumble_rate_diff = pressure_fumble_rate - clean_fumble_rate,
    total_turnover_diff = int_rate_diff + fumble_rate_diff,
    
    .groups = 'drop'
  ) %>%
  filter(!is.na(total_turnover_diff),
         dropbacks >= 175)
