# Load libraries and data
library(car)
library(dplyr)
library(readr)
library(ggplot2)
library(GGally)
data <- read_csv("data.csv")

# Basic data overview
sapply(subset(data, select = -`Listing ID`), table)
sapply(data, data.class)

# Select the variable that's more correlated
cor(data$`TRY Price`, data$`m² (Brüt)`)
cor(data$`TRY Price`, data$`m² (Net)`)
data <- subset(data, select = -`m² (Net)`)

# Feature engineering: Rank room numbers (ie. make them ordinal)
room_rank_map <- c("Stüdyo (1+0)" = 0, "1+1" = 1, "1.5+1" = 1,
                   "2+1" = 2, "2.5+1" = 2, "2+2" = 3,
                   "3+1" = 3, "4+1" = 4, "5+1" = 5)
data$`Room Number Rank` <- room_rank_map[data$`Oda Sayısı`]

# Feature engineering: Assume worst from the notice giver
building_age_map <- c("0" = 0, "1" = 1, "2" = 2, "3" = 3, "4" = 4,
                      "5-10 arası" = 9, "11-15 arası" = 14,
                      "16-20 arası" = 19, "21-25 arası" = 24,
                      "26-30 arası" = 29, "31 ve üzeri" = 35)
data$`Building age Numeric` <- building_age_map[data$`Bina Yaşı`]

# Feature engineering: Map floor levels to numeric values
floor_map <- c("Bahçe Katı" = 0, "Giriş Altı Kot 1" = -1, "Giriş Altı Kot 2" = -1, 
               "Giriş Altı Kot 3" = -1, "Giriş Katı" = 0, "Yüksek Giriş" = 0, 
               "1" = 1, "2" = 2, "3" = 3, "4" = 4, "5" = 5, 
               "6" = 6, "7" = 7, "8" = 8, "9" = 9, "Müstakil" = 0)

data$`Floor Numeric` <- as.numeric(floor_map[data$`Bulunduğu Kat`])
data$`Floor Numeric`[data$`Bulunduğu Kat` == "Çatı Katı"] <- data$`Kat Sayısı`[data$`Bulunduğu Kat` == "Çatı Katı"]
data$`Floor Numeric` <- as.numeric(data$`Floor Numeric` )

# Drop uninformative variables (too little observations on some observations)
table(data$Isıtma)
table(data$`Banyo Sayısı`)
data <- subset(data, select = -c(Isıtma, `Banyo Sayısı`))

# Feature engineering: Assign 0 or 1 to yes or no answers
data$HasParking <- as.numeric(data$Otopark != "Yok")
data$HasBalcony <- as.numeric(data$Balkon == "Var")
data$HasElevator <- as.numeric(data$Asansör == "Var")
data$IsFurnished <- as.numeric(data$Eşyalı == "Evet")

# Drop the non-engineered variables
data <- subset(data, select = -c(
  `Oda Sayısı`, `Bina Yaşı`, `Bulunduğu Kat`, `Kat Sayısı`, 
  `Balkon`, `Asansör`, `Otopark`, `Eşyalı`, 
  `Site İçerisinde`, `Aidat (TL)`, `Depozito (TL)`
))


# Iteratively remove variables that produce multicollinearity problems:
model <- lm(`TRY Price` ~ `m² (Brüt)`, data = data)
summary(model)

# Room Number variable produced a non-logical result of negative association
model <- lm(`TRY Price` ~ `m² (Brüt)` + `Room Number Rank`, data = data)
summary(model)
vif(model, type = "predict")
data <- subset(data, select = -c(`Room Number Rank`))

# Has balcony variable's p value came out too great
model <- lm(`TRY Price` ~ `m² (Brüt)` + `Building age Numeric` +
              `Floor Numeric` + `HasParking` + `HasBalcony` +
              `HasElevator` + `IsFurnished`, data = data)
summary(model)
vif(model)

data <- subset(data, select = -c(`HasBalcony`))


# The Model Looks Great!
model <- lm(`TRY Price` ~ `m² (Brüt)` + `Building age Numeric` +
              `Floor Numeric` + `HasParking`+
              `HasElevator` + `IsFurnished`, data = data)
summary(model)
vif(model)





# Save diagnostic plots as JPEGs
jpeg_filenames <- c("residuals_vs_fitted.jpeg", "normal_qq.jpeg", 
                    "scale_location.jpeg", "residuals_vs_leverage.jpeg")
plot_colors <- list(points = "blue", line = "red", background = "white")

# Generate and save each diagnostic plot
jpeg(file = jpeg_filenames[1], width = 800, height = 800)
par(bg = plot_colors$background)
plot(model, which = 1, col = plot_colors$points, pch = 16, cex = 1.2, main = "Residuals vs Fitted")
abline(h = 0, col = plot_colors$line, lwd = 2)
dev.off()

jpeg(file = jpeg_filenames[2], width = 800, height = 800)
par(bg = plot_colors$background)
plot(model, which = 2, col = plot_colors$points, pch = 16, cex = 1.2, main = "Normal Q-Q")
qqline(residuals(model), col = plot_colors$line, lwd = 2)
dev.off()

jpeg(file = jpeg_filenames[3], width = 800, height = 800)
par(bg = plot_colors$background)
plot(model, which = 3, col = plot_colors$points, pch = 16, cex = 1.2, main = "Scale-Location")
dev.off()

jpeg(file = jpeg_filenames[4], width = 800, height = 800)
par(bg = plot_colors$background)
plot(model, which = 5, col = plot_colors$points, pch = 16, cex = 1.2, main = "Residuals vs Leverage")
abline(h = 0, col = plot_colors$line, lwd = 2)
dev.off()

# Influence plot for diagnostics
influencePlot(model)

# Function for removing outliers using Z-Score
clean_outliers_zscore <- function(df, columns = NULL, z_threshold = 4) {
  if (is.null(columns)) {
    columns <- colnames(df)  # Use all columns if none are specified
  }
  
  for (col in columns) {
    if (is.numeric(df[[col]])) {  # Check if column is numeric
      z_scores <- scale(df[[col]], center = TRUE, scale = TRUE)  # Compute Z-scores
      df <- df %>% 
        filter(abs(z_scores) <= z_threshold)  # Filter based on Z-score threshold
    }
  }
  return(df)  # Return cleaned data
}
cleaned_data <- clean_outliers_zscore(data, z_threshold = 4)
# Using a lenient Z-score threshold of 4



# The "HasParking" variable was eliminated as a result of cleaning
cleaned_model <- lm(`TRY Price` ~ `m² (Brüt)` + `Building age Numeric` +
                      `Floor Numeric` +
                      `HasElevator` + `IsFurnished`, data = cleaned_data)
summary(cleaned_model)
vif(cleaned_model)




# Identify and remove top 10 most influential points
cooks_distances <- cooks.distance(cleaned_model)
top_10_influential_points <- order(cooks_distances, decreasing = TRUE)[1:10]
cleaned_data <- cleaned_data[-top_10_influential_points, ]

influencePlot(cleaned_model)

# The Building Age variable's p-value increased too much, so we're dropping it
cleaned_model <- lm(`TRY Price` ~ `m² (Brüt)` +
                      `Floor Numeric` +
                      `HasElevator` + `IsFurnished`, data = cleaned_data)
summary(cleaned_model)
vif(cleaned_model)

# Transformations
# As a last step let's normalize the variables that are appropriate for it:
# normalize TRY Price
cleaned_data$`TRY Price` <- (cleaned_data$`TRY Price` - min(cleaned_data$`TRY Price`)) / 
  (max(cleaned_data$`TRY Price`) - min(cleaned_data$`TRY Price`))
# normalize m^2 data
cleaned_data$`m² (Brüt)` <- (cleaned_data$`m² (Brüt)` - min(cleaned_data$`m² (Brüt)`)) / 
  (max(cleaned_data$`m² (Brüt)`) - min(cleaned_data$`m² (Brüt)`))

final_model <- lm(`TRY Price` ~ `m² (Brüt)` +
                      `Floor Numeric` +
                      `HasElevator` + `IsFurnished`, data = cleaned_data)
summary(final_model)
vif(final_model)



# Calculate the residuals
residuals <- final_model$residuals
mse <- mean(residuals^2)
print(mse)


# ************************************************
# The rest of the code is for generating diagnostic plots
# File paths for saving the plots
jpeg_filenames <- c("residuals_vs_fitted.jpeg",
                    "normal_qq.jpeg",
                    "scale_location.jpeg",
                    "residuals_vs_leverage.jpeg",
                    "scatter_m2_vs_price.jpeg",
                    "scatter_floor_vs_price.jpeg",
                    "scatter_elevator_vs_price.jpeg",
                    "scatter_furnished_vs_price.jpeg")

# Custom color scheme
plot_colors <- list(
  points = "blue",
  line = "red",
  background = "white"
)

# Function to create diagnostic plots
create_diagnostic_plots <- function(model, filenames, plot_colors) {
  plot_types <- list("Residuals vs Fitted" = 1, "Normal Q-Q" = 2, "Scale-Location" = 3, "Residuals vs Leverage" = 5)
  for (i in seq_along(plot_types)) {
    jpeg(file = filenames[i], width = 800, height = 800)
    par(bg = plot_colors$background)
    plot(model, which = plot_types[[i]], col = plot_colors$points, pch = 16, cex = 1.2, main = names(plot_types)[i])
    if (i == 1 || i == 4) {
      abline(h = 0, col = plot_colors$line, lwd = 2)
    }
    if (i == 2) {
      qqline(residuals(model), col = plot_colors$line, lwd = 2)
    }
    dev.off()
  }
}

# Function to create scatter plots
create_scatter_plots <- function(data, filenames, plot_colors) {
  plot_vars <- list(`m² (Brüt)` = "TRY Price",
                    `Floor Numeric` = "TRY Price",
                    `HasElevator` = "TRY Price",
                    `IsFurnished` = "TRY Price")
  plot_labels <- c("m² (Brüt)", "Floor Numeric", "Has Elevator (0 = No, 1 = Yes)", "Is Furnished (0 = No, 1 = Yes)")
  for (i in seq_along(plot_vars)) {
    jpeg(file = filenames[i+4], width = 800, height = 800)  # Offset by number of diagnostic plots
    par(bg = plot_colors$background)
    plot(data[[names(plot_vars)[i]]], data[[plot_vars[[i]]]], col = plot_colors$points, pch = 16, cex = 1.2,
         main = paste(names(plot_vars)[i], "vs TRY Price"), xlab = plot_labels[i], ylab = "TRY Price")
    abline(lm(data[[plot_vars[[i]]]] ~ data[[names(plot_vars)[i]]], data = data), col = plot_colors$line, lwd = 2)
    dev.off()
  }
}

# Generate diagnostic plots
create_diagnostic_plots(cleaned_model, jpeg_filenames[1:4], plot_colors)

# Generate scatter plots
create_scatter_plots(cleaned_data, jpeg_filenames, plot_colors)