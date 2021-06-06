# European map of average weighted values (in %) for the forest fractional cover

This repo demonstrates how to easily overlay community polygons on forest cover data and make a beautiful map using ``R`` and ``ggplot2``.

The R code helps you overlay community spatial polygons over forest cover satellite imagery to compute and map the average percentage of the land area under forest using no more than 200 lines of code. 

The data on fractional forest cover from [Global Land Cover](https://lcviewer.vito.be/download) of the Copernicus Monitoring Services. The shapefile of over 122,000 communities in Europe comes from Eurostat's GISCO [repo](https://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/communes#communes16). The code overlay this shapefile on the forest cover data using function ``exact_extract`` from library [exactextract](https://github.com/isciences/exactextract) to compute the average value of each forest cover cell that intersects the community polygons, weighted by the percent of the cell that is covered. This will yield the average percentage of the forest cover for a specific community.

![alt text](https://github.com/milos-agathon/forest_map_europe/blob/main/forest_cover_2019.png?raw=true)
