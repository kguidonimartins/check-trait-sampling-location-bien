# install/load packages
if (!require("DBI")) {
  install.packages("DBI")
}
if (!require("RSQLite")) {
  install.packages("RSQLite")
}
if (!require("dplyr")) {
  install.packages("dplyr")
}
if (!require("ggplot2")) {
  install.packages("ggplot2")
}
if (!require("dbplyr")) {
  install.packages("dbplyr")
}
if (!require("shiny")) {
  install.packages("shiny")
}

# connect o db
con <- DBI::dbConnect(
  drv = RSQLite::SQLite(),
  "bien.db"
)

# source db
src_dbi(con)

# generate input variables
traits <- con %>%
  tbl("all_traits_from_bien") %>%
  distinct(trait_name) %>%
  collect() %>%
  pull()

species <- con %>%
  tbl("all_traits_from_bien") %>%
  distinct(scrubbed_species_binomial) %>%
  collect() %>%
  pull()

# Define UI for application
ui <- fluidPage(

  # Application title
  titlePanel("Check trait sampling location of BIEN"),

  # Choose traits and species
  sidebarLayout(
    sidebarPanel(
      selectInput("traits",
        "Select trait:",
        choices = traits
      ),
      selectInput("species",
        "Select species:",
        choices = species
      )
    ),

    # Show map
    mainPanel(
      plotOutput("map_plot",
        width = "1200px",
        height = "600px"
      )
    )
  )
)

# Define server logic required to draw the map
server <- function(input, output) {
  output$map_plot <- renderPlot({
    map_border <- borders(
      database = "world",
      fill = "white",
      colour = "grey90"
    )


    withProgress(
      message = "Creating map ...",
      {
        var_trait <- input$traits
        var_species <- input$species

        filtered_data <-
          con %>%
          tbl("all_traits_from_bien") %>%
          filter(scrubbed_species_binomial == var_species, trait_name == var_trait) %>%
          collect()

        n_sampling <- nrow(filtered_data)
        filtered_data %>%
          ggplot() +
          map_border +
          theme_bw() +
          labs(
            x = "Longitude (decimals)",
            y = "Latitude (decimals)"
          ) +
          theme(
            panel.border = element_blank(),
            panel.grid.major = element_line(colour = "grey80"),
            panel.grid.minor = element_blank()
          ) +
          geom_point(
            aes(
              x = longitude,
              y = latitude
            ),
            alpha = 0.5,
            size = 1
          ) +
          labs(
            title = paste(n_sampling, "samplings for", var_species)
          )
      }
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
