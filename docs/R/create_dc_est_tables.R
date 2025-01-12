library(tidyverse)

hh_raw <- read_csv("data/output/_PRIVATE/survey_processing/hh_processed.csv")
trips_raw <- read_csv("data/output/_PRIVATE/survey_processing/trips_processed.csv")
cluster <- read_csv("data/input/dc/cluster_def.csv")

# W_HB_W
df_w_hbw <- trips_raw %>%
  filter(trip_type == "W_HB_W_All", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerWorker = hh_income_midpt / num_workers,
    LowIncome = ifelse(AvgIncPerWorker < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerWorker,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_w_hbw, "data/output/resident_dc/w_hbw_est_tbl.csv")

# W_HB_O
df_w_hbo <- trips_raw %>%
  filter(trip_type == "W_HB_O_All", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerWorker = hh_income_midpt / num_workers,
    LowIncome = ifelse(AvgIncPerWorker < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerWorker,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_w_hbo, "data/output/resident_dc/w_hbo_est_tbl.csv")

# W_HB_EK12
df_w_ek12 <- trips_raw %>%
  filter(trip_type == "W_HB_EK12_All", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerWorker = hh_income_midpt / num_workers,
    LowIncome = ifelse(AvgIncPerWorker < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerWorker,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_w_ek12, "data/output/resident_dc/w_hb_ek12_est_tbl.csv")

# OME
df_ome <- trips_raw %>%
  filter(trip_type == "N_HB_OME_All", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerAdult = hh_income_midpt / num_adults,
    LowIncome = ifelse(AvgIncPerAdult < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerAdult,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_ome, "data/output/resident_dc/ome_est_tbl.csv")

# OD Short
df_ods <- trips_raw %>%
  filter(trip_type == "N_HB_OD_Short", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerAdult = hh_income_midpt / num_adults,
    LowIncome = ifelse(AvgIncPerAdult < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerAdult,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_ods, "data/output/resident_dc/ods_est_tbl.csv")

# OD Long
df_odl <- trips_raw %>%
  filter(trip_type == "N_HB_OD_Long", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerAdult = hh_income_midpt / num_adults,
    LowIncome = ifelse(AvgIncPerAdult < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerAdult,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_ods, "data/output/resident_dc/odl_est_tbl.csv")

# OMED
df_omed <- trips_raw %>%
  filter(trip_type == "N_HB_OMED_All", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerAdult = hh_income_midpt / num_adults,
    LowIncome = ifelse(AvgIncPerAdult < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerAdult,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_omed, "data/output/resident_dc/omed_est_tbl.csv")

# N_HB_K12
df_hb_k12 <- trips_raw %>%
  filter(trip_type == "N_HB_K12_All", mode_simple != "walkbike") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerAdult = hh_income_midpt / num_adults,
    LowIncome = ifelse(AvgIncPerAdult < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, HomeTAZ, o_taz, d_taz, a_taz,
    mode_final, HHIncomeMP = hh_income_midpt, AvgIncPerAdult,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_hb_k12, "data/output/resident_dc/n_hb_k12_est_tbl.csv")

## IZ %s
iz_df <- trips_raw %>%
  filter(mode_simple != "walkbike", tour_type != "H") %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(iz = ifelse(p_taz == a_taz, "IZ", "NotIZ")) %>%
  group_by(trip_type, iz) %>%
  summarize(trips = sum(trip_weight_combined)) %>%
  filter(!is.na(iz)) %>%
  mutate(
    pct = round(trips / sum(trips) * 100, 1),
    trips = round(trips, 0)
  ) %>%
  pivot_wider(id_cols = trip_type, names_from = iz, values_from = c(trips, pct))
write_csv(iz_df, "data/output/resident_dc/intrazonals.csv")

# NHB trips
df_nhb <- trips_raw %>%
  filter(tour_type != "H" & homebased == "NH") %>%
  left_join(
    hh_raw %>%
      select(hhid, hh_income_midpt, num_adults),
    by = "hhid"
  ) %>%
  group_by(personid, tour_num, a_taz) %>%
  slice(1) %>%
  mutate(
    HomeTAZ = ifelse(pa_flag == 1, o_taz, d_taz),
    AvgIncPerAdult = hh_income_midpt / num_adults,
    LowIncome = ifelse(AvgIncPerAdult < 75000, 1, 0)
  ) %>%
  left_join(cluster, by = c("HomeTAZ" = "TAZ")) %>%
  rename(Home_Cluster = Cluster) %>%
  left_join(cluster, by = c("o_taz" = "TAZ")) %>%
  rename(O_Cluster = Cluster) %>%
  left_join(cluster, by = c("d_taz" = "TAZ")) %>%
  rename(D_Cluster = Cluster) %>%
  mutate(ZeroAutoHH = ifelse(num_vehicles == 0, 1, 0)) %>%
  filter(
    !(mode_final %in% c("XXX", "school_bus", "other")),
    !is.na(HomeTAZ)
  ) %>%
  mutate(mode_group = case_when(
    mode_final %in% c("eb", "lb") ~ "transit",
    mode_final == "walkbike" ~ "nonmotorized",
    TRUE ~ "auto"
  )) %>%
  ungroup() %>%
  select(
    EstDataID = seqtripid, personid, hhid, trip_type, mode = mode_final, mode_group, HomeTAZ, o_taz, d_taz, a_taz,
    HHIncomeMP = hh_income_midpt, AvgIncPerAdult,
    LowIncome, Home_Cluster, O_Cluster, D_Cluster, Segment = choice_segment,
    tod,
    ZeroAutoHH, trip_weight = trip_weight_combined, hh_weight = hh_weight_combined
  )
write_csv(df_nhb, "data/output/resident_dc/nhb_est_tbl.csv")
