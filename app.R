library(shiny)
library(leaflet)
library(sf)
library(dplyr)
library(ggplot2)
library(shinyWidgets)
library(qs)

# ---- Série temporelle ----
annees <- 2006:2024

# ---- Base URL GitHub ----
base_url <- "https://raw.githubusercontent.com/hgesdrn/TBE_QC_shiny/main/data/"

# ---- Fonction pour charger un .qs depuis GitHub ----
charger_qs_github <- function(fichier_qs_url) {
  temp <- tempfile(fileext = ".qs")
  download.file(fichier_qs_url, temp, mode = "wb", quiet = TRUE)
  qs::qread(temp)
}

# ---- Contour Québec ----
qc_contour <- readRDS(url("https://raw.githubusercontent.com/hgesdrn/TBE_QC_shiny/main/data/prov_sf.rds"))

# ---- Table tabulaire fusionnée ----
df_tbe_tabulaire <- charger_qs_github(paste0(base_url, "TBE_table_complete_v3.qs"))

# ---- UI ----
ui <- fluidPage(
  titlePanel(NULL),
  tags$style(HTML("
    .header-title {
      background-color: #2C3E50;
      color: white;
      padding: 20px;
      font-size: 22px;
      font-weight: bold;
      text-align: left;
      text-transform: uppercase;
      border-radius: 0px;
      margin-bottom: 20px;
      box-shadow: 2px 2px 8px rgba(0,0,0,0.2);
    }
    .box-style {
      background-color: #f9f9f9;
      border: 1px solid #ccc;
      border-radius: 8px;
      padding: 20px;
      box-shadow: 2px 2px 8px rgba(0,0,0,0.1);
      height: 700px;
      overflow-y: auto;
    }
  ")),
  div("Superficie annuelle affectée par la TBE de 2006 à 2024", class = "header-title"),
  fluidRow(
    column(6,
           div(class = "box-style",
               sliderTextInput(
                 inputId = "annee",
                 label = "Choisissez une année :",
                 choices = as.character(annees),
                 selected = "2006",
                 grid = TRUE,
                 width = "100%"
               ),
               plotOutput("plot_saguenay", height = "250px"),
               plotOutput("plot_quebec", height = "250px")
           )
    ),
    column(6,
           div(class = "box-style",
               leafletOutput("map", height = "640px")
           )
    )
  )
)

# ---- Serveur ----
server <- function(input, output, session) {
  
  rv <- reactiveValues(tbe_data = list())
  
  # Charger tous les polygones au démarrage
  observe({
    for (yr in annees) {
      isolate({
        url_fichier <- paste0(base_url, "TBE_", yr, "_v3.qs")
        message("Chargement : ", url_fichier)
        rv$tbe_data[[as.character(yr)]] <- charger_qs_github(url_fichier)
      })
    }
  })
  
  data_filtered <- reactive({
    req(input$annee)
    rv$tbe_data[[input$annee]]
  })
  
  # Carte
  output$map <- renderLeaflet({
    bbox <- st_bbox(qc_contour)
    leaflet(options = leafletOptions(preferCanvas = TRUE)) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        data = qc_contour,
        color = NA,
        fillColor = "gray20",
        fillOpacity = 0.4,
        weight = 0,
        group = "Province"
      ) %>%
      fitBounds(lng1 = bbox[["xmin"]], lat1 = 45.0,
                lng2 = bbox[["xmax"]], lat2 = 52.5)
  })
  
  # Mise à jour polygones
  observeEvent(input$annee, {
    req(data_filtered())
    leafletProxy("map") %>%
      clearGroup("TBE") %>%
      addPolygons(
        data = data_filtered(),
        group = "TBE",
        fillColor = "#085016",
        fillOpacity = 0.7,
        color = NA,
        weight = 0
      )
  })
  
  # Graphique Saguenay
  output$plot_saguenay <- renderPlot({
    df_sag <- df_tbe_tabulaire %>%
      filter(RES_NM_REG == "Saguenay–Lac-Saint-Jean",
             !is.na(AN_TBE), AN_TBE %in% annees) %>%
      group_by(AN_TBE) %>%
      summarise(SUP_HA = sum(SUP_HA, na.rm = TRUE)) %>%
      mutate(SUP_HA = SUP_HA / 1e6,
             couleur = ifelse(AN_TBE == as.numeric(input$annee), "Sélectionnée", "Autre"))
    
    ggplot(df_sag, aes(x = factor(AN_TBE), y = SUP_HA, fill = couleur)) +
      geom_bar(stat = "identity") +
      geom_text(data = subset(df_sag, couleur == "Sélectionnée"),
                aes(label = sprintf("%.1f", SUP_HA)),
                vjust = -0.5, color = "black", size = 4) +
      ylim(0, 15) +
      scale_fill_manual(values = c("Sélectionnée" = "#4a5a76", "Autre" = "gray50"), guide = "none") +
      labs(title = "Saguenay–Lac-Saint-Jean", x = NULL, y = "Superficie (millions ha)") +
      theme_minimal()
  })
  
  # Graphique Québec
  output$plot_quebec <- renderPlot({
    df_quebec <- df_tbe_tabulaire %>%
      group_by(AN_TBE) %>%
      summarise(SUP_HA = sum(SUP_HA, na.rm = TRUE)) %>%
      mutate(SUP_HA = SUP_HA / 1e6,
             couleur = ifelse(AN_TBE == as.numeric(input$annee), "Sélectionnée", "Autre"))
    
    ggplot(df_quebec, aes(x = factor(AN_TBE), y = SUP_HA, fill = couleur)) +
      geom_bar(stat = "identity") +
      geom_text(data = subset(df_quebec, couleur == "Sélectionnée"),
                aes(label = sprintf("%.1f", SUP_HA)),
                vjust = -0.5, color = "black", size = 4) +
      ylim(0, 15) +
      scale_fill_manual(values = c("Sélectionnée" = "#085016", "Autre" ="gray50"), guide = "none") +
      labs(title = "Province du Québec", x = NULL, y = "Superficie (millions ha)") +
      theme_minimal()
  })
}

shinyApp(ui, server)
