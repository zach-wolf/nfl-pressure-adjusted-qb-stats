# NFL Pressure-Adjusted QB Statistics

Advanced quarterback analytics that evaluate performance independent of offensive line quality, featuring the novel Pressure-Adjusted EPA metric.

## Problem Statement

Traditional QB statistics can be misleading when comparing players with vastly different protection levels. A quarterback facing pressure on 25% of dropbacks versus 7% operates under fundamentally different conditions, yet standard metrics treat their performances equally.

## Primary Innovation: Pressure-Adjusted EPA

This project's main contribution is **Pressure-Adjusted EPA** - a comprehensive metric that standardizes QB performance to league-average pressure conditions.

### Pressure-Adjusted EPA+

**The core metric for evaluating QB talent independent of protection:**
- Adjusts every QB's performance to the same pressure environment
- Reveals who would excel with average offensive line protection
- Shows which QBs are being helped/hurt by their circumstances
- **Scale**: 100 = league average, 133 = elite (+1 standard deviation)

![Pressure-Adjusted EPA vs Actual EPA](visualizations/actual_vs_adjusted.png)

*QBs above the diagonal line benefit from pressure adjustment (face tougher conditions), while those below are helped by better protection.*

**Key Insights:**
- Some "struggling" QBs are actually above average talents behind poor protection
- Some "elite" QBs benefit significantly from exceptional protection
- Identifies undervalued QBs who excel despite difficult circumstances

### Supporting Metrics

**Pressure Differential Score** 
- Measures pressure resistance relative to league average
- Validates the Pressure-Adjusted EPA findings

**Decision-Making Under Pressure**
- Separates mental processing from physical execution
- Provides additional context for pressure performance

## Key Findings

- **Protection ≠ Performance**: Some highly-protected QBs perform poorly when protection breaks down
- **Mobile QB Myth**: Mobile QBs don't necessarily face less pressure than pocket passers
- **Pressure Resistance vs. Raw Talent**: Independent evaluation reveals QBs who excel despite circumstances

## Methodology

### Pressure Definition
Due to nflfastR data limitations, pressure is defined as plays where the QB was hit or sacked (≈14% of dropbacks). While this excludes hurries, it captures high-impact pressure situations where protection completely failed.

### Data Sources
- **nflfastR**: Play-by-play data (2018-2024)
- **NextGen Stats**: CPOE and air yards analysis
- **Sample**: QBs with 175+ dropbacks per season

### Validation
Analysis includes CPOE (completion percentage over expected) and air yards to validate EPA findings and understand QB decision-making under pressure.

## Getting Started

Clone the repository and run the analysis pipeline:

```r
# Load required libraries
library(tidyverse)
library(nflreadr)
library(nflfastR)

# Run analysis pipeline
source("scripts/data_collection.R")
source("scripts/core_metrics.R")
source("scripts/visualizations.R")
```

**Note**: Raw data files are not included due to size. Scripts will download current nflfastR data automatically.

## Limitations

- Pressure definition excludes hurries (≈60-70% of total pressure situations)
- Play-level time-to-throw data not available in nflfastR
- Analysis focuses on regular season performance only
- Minimum sample size requirements may exclude some backup QBs

## Applications

- Scouting and player evaluation
- Contract negotiation context
- Identifying undervalued/overvalued QBs in free agency

## License

MIT License - feel free to use for research, analysis, or commercial applications.
