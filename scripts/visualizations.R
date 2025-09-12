library(tidyverse)
library(ggrepel)

source("scripts/ngs_integration.R")

# Pressure-Adjusted EPA+ vs Actual EPA+
actual_vs_adjusted <- final_metrics %>%
  filter(season == 2024) %>%
  ggplot(aes(x = epa_plus, y = adjusted_epa_plus)) +
  geom_point(aes(color = plus_diff), size = 2.75) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  geom_text_repel(aes(label = player_name), size = 2.75) +
  scale_color_gradient2(low = "red", mid = "white", high = "blue", 
                        name = "Performance\nImpact") +
  labs(title = "2024 QB Performance: Actual vs Pressure-Adjusted",
       caption = "*minimum 175 dropbacks",
       x = "Actual EPA+", y = "Pressure-Adjusted EPA+") +
  coord_fixed() +
  theme_minimal() 

ggsave(plot = actual_vs_adjusted,
       filename = "output/figures/actual_vs_adjusted.png",
       width = 8,
       height = 8)

performance_impact <- final_metrics %>%
  filter(season == 2024) %>%
  arrange(plus_diff) %>%
  mutate(player_name = factor(player_name, levels = player_name)) %>%
  ggplot(aes(x = player_name, y = plus_diff)) +
  geom_col(aes(fill = plus_diff > 0), show.legend = FALSE) +
  scale_fill_manual(values = c("red", "blue")) +
  scale_y_continuous(labels = function(x) ifelse(x > 0, paste0("+", x), as.character(x)), breaks = c(-30,-20,-10,0,10,20,30)) +
  coord_flip() +
  labs(
    title = "2024 QB Performance Impact",
    subtitle = "Difference between Pressure-Adjusted EPA+ and Actual EPA+",
    x = "Quarterback",
    y = "EPA+ Gain from Pressure Adjustment",
    caption = "Positive = Benefits from pressure adjustment | Negative = Hurt by pressure adjustment"
  ) +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 8),
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave(plot = performance_impact,
       filename = "output/figures/performance_impact.png",
       width = 9,
       height = 6.5)

# Show relationship between pressure faced and performance drop
pressure_performance <- final_metrics %>%
  filter(season == 2024) %>%
  ggplot(aes(x = pressure_rate, y = plus_diff)) +
  geom_point(aes(size = dropbacks), alpha = 0.7, color = "orange") +
  geom_smooth(method = "lm", se = TRUE) +
  geom_text_repel(aes(label = player_name), size = 2.75) +
  scale_x_continuous(labels = scales::percent_format()) + 
  scale_y_continuous(labels = function(x) ifelse(x > 0, paste0("+", x), as.character(x)), breaks = c(-30,-20,-10,0,10,20,30)) +
  labs(title = "Pressure Rate vs Performance Impact",
       x = "Pressure Rate Faced", 
       y = "Pressure-Adjusted Gain (EPA+ Points)") +
  theme_minimal()

ggsave(plot = pressure_performance,
       filename = "output/figures/pressure_performance.png",
       width = 8,
       height = 8)

# Show relationship between scrambling and performance drop
scrambling_performance <- final_metrics %>%
  filter(season == 2024) %>%
  ggplot(aes(x = scramble_rate, y = plus_diff)) +
  geom_point(aes(size = dropbacks), alpha = 0.7, color = "orange") +
  geom_vline(xintercept = 0.05) +
  geom_hline(yintercept = 0) +
  geom_text_repel(aes(label = player_name), size = 3.5) +
  scale_x_continuous(labels = scales::percent_format(), breaks = c(0,0.025,0.05,0.075,0.1,0.125,0.15)) +
  scale_y_continuous(labels = function(x) ifelse(x > 0, paste0("+", x), as.character(x)), breaks = c(-30,-20,-10,0,10,20,30)) +
  # Add quadrant labels
  annotate("text", x = max(final_metrics$scramble_rate[final_metrics$season == 2024], na.rm = TRUE) * 1.05, y = 0.5, label = "Mobile QB", hjust = 1, vjust = -0.5, size = 4, fontface = "bold") +
  annotate("text", x = -0.005, y = 0.5, label = "Pocket Passer", hjust = 0, vjust = -0.5, size = 4, fontface = "bold") +
  annotate("text", x = 0.05, y = 30, label = "Poor Protection", hjust = -0.1, vjust = 1, size = 4, fontface = "bold") +
  annotate("text", x = 0.05, y = -30, label = "Good Protection", hjust = -0.1, vjust = 0, size = 4, fontface = "bold") +
  labs(title = "Scramble Rate vs Performance Impact",
       x = "Scramble Rate", 
       y = "Pressure-Adjusted Gain (EPA+ Points)") +
  theme_minimal()

ggsave(plot = scrambling_performance,
       filename = "output/figures/scrambling_performance.png",
       width = 10,
       height = 8)

qb_2024_table <- final_metrics %>%
  filter(season == 2024) %>%
  select(player_name, adjusted_epa_plus, epa_plus, plus_diff) %>%
  mutate(adj_epa_rank = rank(-adjusted_epa_plus),
         epa_rank = rank(-epa_plus),
         rank_diff = epa_rank - adj_epa_rank) %>%
  arrange(desc(adjusted_epa_plus))
