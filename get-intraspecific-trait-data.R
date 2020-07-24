# ipak function: install and load multiple R packages.
# Check to see if packages are installed.
# Install them if they are not, then load them into the R session.
# Forked from: https://gist.github.com/stevenworthington/3178163
ipak <- function(pkg) {
  new_pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new_pkg)) {
    install.packages(new_pkg, dependencies = TRUE)
  }
  suppressPackageStartupMessages(sapply(pkg, require, character.only = TRUE))
}


ipak(
  c(
    "tidyverse",
    "future",
    "furrr",
    "parallel",
    "doParallel",
    "BIEN",
    "here"
  )
)

set.seed(19890106)

get_sample_itv_trait <- function(trait) {
  trait_intra_all <- BIEN_trait_trait(trait = trait) %>%
    filter(!is.na(scrubbed_species_binomial))

  # species with < 10 measurements
  spp_below_10 <-
    trait_intra_all %>%
    group_by(scrubbed_species_binomial) %>%
    count(sort = TRUE) %>%
    filter(n < 10) %>%
    pull(scrubbed_species_binomial)

  # filter out spp_below_10
  trait_intra_all_filtered <-
    trait_intra_all %>%
    filter(!scrubbed_species_binomial %in% spp_below_10)

  return(trait_intra_all_filtered)
}

# get trait list
trait_list <- BIEN_trait_list() %>%
  drop_na()

# plan
plan(multiprocess)

# run
multi_trait <-
  furrr::future_map_dfr(
    .x = trait_list$trait_name,
    .f = get_sample_itv_trait,
    .progress = TRUE
  )

# save the data
write_csv(multi_trait, here("data", "all_traits_from_bien.csv"))
