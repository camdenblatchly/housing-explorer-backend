library(DBI)
library(dplyr)
library(tidyr)
library(tidycensus)

here::i_am("R/load-db.R")

app_db <- dbConnect(RSQLite::SQLite(), here::here("database.db"))

acs_vars <- c(
  "pop_total" = "B17001_001",
  "median_gross_rent" = "B25064_001",
  "median_hh_income" = "B19013_001",
  "housing_units_total" = "B25003_001",
  "housing_units_owner_occupied" = "B25003_002",
  "housing_units_renter_occupied" = "B25003_003",
  "median_hh_value" = "B25077_001",
  "hh_total" = "B25070_001",
  "hh_rent_burdened" = "B25070_008",
  "hh_rent_burdened" = "B25070_009",
  "hh_rent_burdened" = "B25070_010",
  "rent_burden" = "B25071_001",
  "housing_units_occupancy_total" = "B25002_001",
  "housing_units_occupied" = "B25002_002",
  "housing_units_vacant" = "B25002_003"
)

acs_dta <- get_acs("place", variables = acs_vars, year = 2021) %>%
  select(GEOID, NAME, variable, estimate) %>%
  group_by(GEOID, NAME, variable) %>%
  summarise(
    estimate = sum(estimate, na.rm = T)
  ) %>%
  tidyr::pivot_wider(
    names_from = "variable",
    values_from = "estimate"
  ) %>%
  mutate(
    pct_renter_occupied = housing_units_renter_occupied / housing_units_total,
    pct_owner_occupied = housing_units_owner_occupied / housing_units_total,
    pct_rent_burdened = hh_rent_burdened / hh_total,
    pct_occupied = housing_units_occupied / housing_units_occupancy_total,
    pct_vacant = housing_units_vacant / housing_units_occupancy_total
  ) %>%
  mutate(GEOID = stringr::str_pad(GEOID, 7, side = "left", pad = "0"))


nzlud <- data.table::fread("https://raw.githubusercontent.com/mtmleczko/nzlud/main/nzlud_muni.csv") %>%
  mutate(GEOID = stringr::str_pad(GEOID, 7, side = "left", pad = "0"))

nzlud_acs <- inner_join(
  nzlud,
  acs_dta,
  by = "GEOID"
)

dbWriteTable(app_db, "acs_zoning", nzlud_acs, overwrite = TRUE)

dbDisconnect(app_db)

