all_data <- here::here("data", "all_traits_from_bien.csv")

if (!file.exists(all_data)) {

  ipak <- function(pkg) {
    new_pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if (length(new_pkg)) install.packages(new_pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
  }

  ipak(
    c(
      "tidyverse",
      "future",
      "furrr",
      "parallel",
      "doParallel",
      "BIEN",
      "here",
      "fs",
      "glue",
      "vroom"
    )
  )

  dir_create(here::here("data", "raw"))
  dir_create(here::here("data", "clean"))

  get_sample_itv_trait <- function(trait) {

    save_to <- here::here("data", "raw", glue("{trait}.csv"))

    if (!file.exists(save_to)) {

      message(glue("Getting data for {trait}"))

      trait_intra_all <- BIEN_trait_trait(trait = trait)

      trait_intra_all %>%
        write_csv(save_to)

    } else {

      message(glue("{save_to} already exists!"))

    }

  }

  # get trait list
  trait_list <-
    BIEN_trait_list() %>%
    drop_na()

  message(glue("{nrow(trait_list)} traits available!"))

  # plan
  # plan(multicore)

  for (trait in trait_list$trait_name) {
    get_sample_itv_trait(trait)
  }

  # # run
  # # multi_trait <-
  #   map(
  #     .x = trait_list$trait_name,
  #     .f = get_sample_itv_trait
  #   )

  multi_trait <-
    here::here("data/raw") %>%
    dir_ls(regexp = "\\.csv$") %>%
    map_dfr(vroom, col_types = cols(.default = "c"))

  write_csv(multi_trait, all_data)

}
