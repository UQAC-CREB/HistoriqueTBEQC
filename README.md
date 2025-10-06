# TBE_QC_shiny

[![Deploy Shiny App](https://github.com/hgesdrn/TBE_QC_shiny/actions/workflows/deploy.yml/badge.svg)](https://github.com/hgesdrn/TBE_QC_shiny/actions/workflows/deploy.yml)

Application Shiny permettant de visualiser les superficies affectées par la tordeuse des bourgeons de l’épinette (TBE) au Québec de 2006 à 2024.

🔗 [Accéder à l’application déployée sur shinyapps.io](https://hgesdrn.shinyapps.io/TBE_QC_shiny/)

## Fonctionnalités

- Sélection annuelle via un curseur interactif.
- Carte interactive du Québec avec surimpression des polygones affectés par la TBE.
- Graphique de la superficie annuelle pour la région du Saguenay–Lac-Saint-Jean.
- Graphique de la superficie annuelle pour l’ensemble du Québec.
- Visualisation rapide, fluide et cohérente grâce à une optimisation des données et du code.

## Données

Les fichiers de données sont stockés dans le dossier `data/` et incluent :

- `prov_sf.rds` : contour du Québec avec découpe du Saguenay–Lac-Saint-Jean.
- `TBE_2006.qs` à `TBE_2024.qs` : polygones annuels des superficies affectées par la TBE.

---

🛠️ Déploiement automatique via GitHub Actions
