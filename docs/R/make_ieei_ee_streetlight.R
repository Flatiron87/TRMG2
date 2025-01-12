# Packages ---------------------------------------------------------------------
packages_vector <- c("tidyverse",
                     "readxl",
                     "sf")

need_to_install <- packages_vector[!(packages_vector %in% installed.packages()[,"Package"])]

if (length(need_to_install)) install.packages(need_to_install)

for (package in packages_vector) {
  library(package, character.only = TRUE)
}


# Remote I/O -------------------------------------------------------------------
private_dir <- "data/_PRIVATE/"
data_dir <- "data/input/"

flow_filename <- paste0(private_dir, "streetlight/itre-analysis/EE_Top_50_with_Volumes_April2017_Travel/EE_Top_50_with_Volumes_1142_Travel/EE_Top_50_with_1142_od_all.csv")

taz_shape_filename <- paste0(data_dir, "tazs/master_tazs.shp")
zone_crosswalk_filename <- paste0(data_dir, "ieei/External Station Cross Reference v62tovG2.xlsx")

output_clean_streetlight_filename <- paste0(private_dir, "clean-itre-streetlight.rds")

# Parameters -------------------------------------------------------------------
LAT_LNG_EPSG <- 4326
PLANAR_EPSG <- 3857

# Data Reads -------------------------------------------------------------------
flow_df <- read_csv(flow_filename, col_types = cols(.default = col_character(),
                                                    `Origin Zone ID` = col_integer(),
                                                    `Destination Zone ID` = col_integer()))

taz_sf <- st_read(taz_shape_filename) %>%
  st_transform(LAT_LNG_EPSG)

cross_df <- read_excel(zone_crosswalk_filename, skip = 1L)

# Reductions -------------------------------------------------------------------
working_df <- flow_df %>%
  select(type = `Type of Travel`,
         orig_zone = `Origin Zone ID`,
         dest_zone = `Destination Zone ID`,
         orig_name = `Origin Zone Name`,
         dest_name = `Destination Zone Name`,
         day_type = `Day Type`,
         day_part = `Day Part`,
         orig_pass_through = `Origin Zone Is Pass-Through`,
         dest_pass_through = `Destination Zone Is Pass-Through`,
         flow = `O-D Traffic (Calibrated Index)`,
         duration_sec = `Avg Trip Duration (sec)`) %>%
  mutate(flow = if_else(flow == "N/A", as.double(NA), as.double(flow))) %>%
  mutate(duration_sec = if_else(duration_sec == "N/A" | is.na(duration_sec), as.integer(NA), as.integer(duration_sec)))

join_df <- cross_df %>%
  select(taz = ID, sl_zone = TRMv6_NodeID)

output_df <- left_join(working_df, join_df, by = c("orig_zone" = "sl_zone")) %>%
  rename(orig_taz = taz) %>%
  left_join(., join_df, by = c("dest_zone" = "sl_zone")) %>%
  rename(dest_taz = taz) %>%
  filter(!is.na(orig_taz)) %>%
  filter(!is.na(dest_taz)) %>%
  select(-orig_zone, -dest_zone)


# Write ------------------------------------------------------------------------
saveRDS(output_df, file = output_clean_streetlight_filename)


