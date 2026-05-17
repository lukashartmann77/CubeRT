# ---------------------------------------------------------------------------- #
# Author:      Lukas Hartmann
# Date:        21.05.2025
# File:        rubiks.R
# Description: Analysis of Rubik's cube reaction times
# ---------------------------------------------------------------------------- #

# Load data -------------------------------------------------------------------

rubiks <- read.csv("reactiontime.csv")
rubiks$date <- as.Date(rubiks$date)

# Define rolling mean function ------------------------------------------------

data_rolling_mean <- function(x, window = 5) {
  
  if (length(x) < window) {
    return(rep(NA, length(x)))
  }
  
  if (window %% 2 == 1) {
    n <- floor(window / 2)
    weights <- c(seq(1, n + 1), seq(n, 1))
  } else {
    n <- window / 2
    weights <- c(seq(1, n), seq(n, 1))
  }
  
  weights <- weights / sum(weights)
  
  pad_left <- rev(head(x, n))
  pad_right <- rev(tail(x, n))
  
  x_padded <- c(pad_left, x, pad_right)
  result <- stats::filter(x_padded, weights, sides = 2)
  
  return(as.numeric(result[(n + 1):(length(result) - n)]))
}

# Aggregate data by date ------------------------------------------------------

daily_mean <- aggregate(reactiontime ~ date, data = rubiks, FUN = mean)
daily_min  <- aggregate(reactiontime ~ date, data = rubiks, FUN = min)
daily_max  <- aggregate(reactiontime ~ date, data = rubiks, FUN = max)

rubiks_agg <- merge(daily_mean, daily_min, by = "date")
rubiks_agg <- merge(rubiks_agg, daily_max, by = "date")

colnames(rubiks_agg) <- c(
  "date",
  "daily_mean",
  "daily_min",
  "daily_max"
)

# Configure rolling window ----------------------------------------------------

n <- nrow(rubiks_agg)
window <- floor(n / 2)

if (window %% 2 == 0) {
  window <- window + 1
}

if (window < 3) {
  window <- 3
}

rolling_mean <- data_rolling_mean(rubiks_agg$daily_mean, window)
rolling_min  <- data_rolling_mean(rubiks_agg$daily_min, window)
rolling_max  <- data_rolling_mean(rubiks_agg$daily_max, window)

# Fit linear regression model -------------------------------------------------

lm_model <- lm(daily_mean ~ date, data = rubiks_agg)
lm_summary <- capture.output(summary(lm_model))

# Calculate summary statistics ------------------------------------------------

avg_last_month <- mean(
  rubiks_agg$daily_mean[
    rubiks_agg$date > (max(rubiks_agg$date) - 30)
  ],
  na.rm = TRUE
)

start_date <- min(rubiks_agg$date)
end_date <- max(rubiks_agg$date)

total_observations <- nrow(rubiks)
overall_mean <- mean(rubiks$reactiontime, na.rm = TRUE)
fastest_time <- min(rubiks$reactiontime, na.rm = TRUE)

# Create PDF output -----------------------------------------------------------

pdf(
  "rubiks.pdf",
  width = 10,
  height = 10,
  onefile = TRUE
)

layout(
  matrix(
    c(
      1, 1, 1, 2,
      3, 3, 3, 3,
      4, 4, 5, 5
    ),
    byrow = TRUE,
    nrow = 3
  )
)

# Plot 1: Raw data and linear trend -------------------------------------------

par(mar = c(4, 4.5, 2.5, 1))

plot(
  rubiks_agg$date,
  rubiks_agg$daily_mean,
  type = "b",
  pch = 16,
  col = "grey40",
  lwd = 2,
  xlab = "Date",
  ylab = "Reaction Time (s)",
  main = "Raw Data and Linear Trend",
  xlim = range(rubiks_agg$date),
  ylim = range(rubiks_agg$daily_mean, na.rm = TRUE)
)

abline(
  lm_model,
  col = "red",
  lwd = 2,
  lty = 2
)

legend(
  "topright",
  legend = c("Daily Mean", "Linear Trend"),
  col = c("grey40", "red"),
  lty = c(1, 2),
  pch = c(16, NA),
  lwd = c(2, 2)
)

grid()

# Plot 2: Statistical summary -------------------------------------------------

par(mar = c(1, 1, 1, 1))

plot.new()

text(
  0,
  1,
  "Linear Model Summary and Key Statistics",
  font = 2,
  adj = c(0, 1)
)

text(
  0,
  0.95,
  paste(
    c(
      lm_summary,
      "",
      paste("Total Observations:", total_observations),
      paste("Start Date:", format(start_date)),
      paste("End Date:", format(end_date)),
      paste("Overall Mean (s):", round(overall_mean, 3)),
      paste("Mean Last 30 Days (s):", round(avg_last_month, 3)),
      paste("Rolling Window:", window),
      paste("Fastest Reaction Time (s):", round(fastest_time, 3))
    ),
    collapse = "\n"
  ),
  adj = c(0, 1),
  cex = 0.8
)

# Plot 3: Smoothed trends -----------------------------------------------------

par(mar = c(4, 4.5, 2.5, 1))

plot(
  rubiks_agg$date,
  rubiks_agg$daily_mean,
  type = "n",
  xlab = "Date",
  ylab = "Reaction Time (s)",
  main = paste(
    "Smoothed Trends (Rolling Mean, Window =",
    window,
    ")"
  ),
  ylim = range(c(rolling_min, rolling_max), na.rm = TRUE)
)

lines(rubiks_agg$date, rolling_min, col = "lightblue", lwd = 2, lty = 3)
lines(rubiks_agg$date, rolling_max, col = "lightpink", lwd = 2, lty = 3)
lines(rubiks_agg$date, rolling_mean, col = "black", lwd = 2)

legend(
  "topright",
  legend = c("Smoothed Mean", "Smoothed Min/Max"),
  col = c("black", "lightblue"),
  lty = c(1, 3),
  lwd = c(2, 2)
)

grid()

# Plot 4: Monthly boxplots ----------------------------------------------------

last_12_months <- seq.Date(
  from = max(rubiks_agg$date) - 365,
  to = max(rubiks_agg$date),
  by = "month"
)

months <- format(rubiks$date, "%Y-%m")
valid_months <- unique(format(last_12_months, "%Y-%m"))

recent_data <- rubiks[months %in% valid_months, ]

if (nrow(recent_data) > 0) {
  
  par(mar = c(6, 4.5, 2, 1))
  
  boxplot(
    reactiontime ~ format(date, "%Y-%m"),
    data = recent_data,
    col = heat.colors(length(valid_months), alpha = 0.6),
    las = 2,
    main = "Boxplot: Reaction Times (Last 12 Months)",
    ylab = "Time (s)"
  )
  
} else {
  
  plot.new()
  text(0.5, 0.5, "No data for last 12 months")
}

# Plot 5: Histogram distribution ----------------------------------------------

par(mar = c(4, 4.5, 2.5, 1))

hist(
  rubiks$reactiontime,
  breaks = 30,
  freq = FALSE,
  col = "lightgray",
  border = "white",
  main = "Histogram of Reaction Times",
  xlab = "Reaction Time (s)",
  xlim = c(
    min(rubiks$reactiontime) * 0.9,
    max(rubiks$reactiontime) * 1.1
  )
)

curve(
  dnorm(
    x,
    mean = mean(rubiks$reactiontime, na.rm = TRUE),
    sd = sd(rubiks$reactiontime, na.rm = TRUE)
  ),
  col = "darkblue",
  lwd = 2,
  add = TRUE
)

legend(
  "topright",
  legend = "Normal Curve",
  col = "darkblue",
  lwd = 2
)

grid()

# Finalize output -------------------------------------------------------------

invisible(dev.off())
