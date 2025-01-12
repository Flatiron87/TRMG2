# Packages ---------------------------------------------------------------------
packages_vector <- c("tidyverse")

need_to_install <- packages_vector[!(packages_vector %in% installed.packages()[,"Package"])]

if (length(need_to_install)) install.packages(need_to_install)

for (package in packages_vector) {
  library(package, character.only = TRUE)
}

# Remote I/O -------------------------------------------------------------------
private_dir <- "data/_PRIVATE/"

campo_sl_filename <- paste0(private_dir, "streetlight/161428_TRM20test5_2016/161428_TRM20test5_2016_od_all.csv")
durham_sl_filename <- paste0(private_dir, "streetlight/164792_TRM20_2016_All/164792_TRM20_2016_All_od_all.csv")

output_clean_streetlight_filename <- paste0(private_dir, "clean-streetlight.rds")

# Parameters -------------------------------------------------------------------
LAT_LNG_EPSG <- 4326

# Data Reads -------------------------------------------------------------------
campo_df <- read_csv(campo_sl_filename, col_types = cols(.default = col_character(),
                                                         `Origin Zone ID` = col_integer(),
                                                         `Destination Zone ID` = col_integer()))

durham_df <- read_csv(durham_sl_filename, col_types = cols(.default = col_character(),
                                                           `Origin Zone ID` = col_integer(),
                                                           `Destination Zone ID` = col_integer()))

# Reductions -------------------------------------------------------------------
output_df <- bind_rows(mutate(campo_df, source = "campo"), 
                       mutate(durham_df, source = "durham")) %>%
  select(source,
         type = `Type of Travel`,
         orig_zone = `Origin Zone ID`,
         dest_zone = `Destination Zone ID`,
         orig_name = `Origin Zone Name`,
         dest_name = `Destination Zone Name`,
         day_type = `Day Type`,
         day_part = `Day Part`,
         orig_pass_through = `Origin Zone Is Pass-Through`,
         dest_pass_through = `Destination Zone Is Pass-Through`,
         flow = `Average Daily O-D Traffic (StL Volume)`,
         duration_sec = `Avg Trip Duration (sec)`) %>%
  mutate(flow = if_else(flow == "N/A", as.double(NA), as.double(flow))) %>%
  mutate(duration_sec = if_else(duration_sec == "N/A", as.integer(NA), as.integer(duration_sec)))

# Write ------------------------------------------------------------------------
saveRDS(output_df, file = output_clean_streetlight_filename)


