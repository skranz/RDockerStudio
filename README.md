Simple Docker Container Managment Tool as interactive RStudio Addin

I use this package in rstudio-server to simply manage docker containers on the webserver on which rstudio-server is running. Core idea is to put different shiny apps into different containers. This tool just helps a little bit the management. Best way to use it via the RStudio addin menu.

In principle you could also run it as a shiny app, but be careful: there is no password protection. So hosting it as a publicly available shiny app seems very risky. Everybody could mess up your docker containers on the server. In contrast rstudio-server requires authentification.

