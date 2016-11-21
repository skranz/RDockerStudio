### A very simple Docker container managment Tool as interactive RStudio Addin

I use this package in rstudio-server to simply manage docker containers on the webserver on which rstudio-server is running. Core idea is to put different shiny apps into different containers. This tool just helps a little bit the management. For more complicated docker command you should use the command line.

Best way to use the tool is it via the RStudio addin menu.

In theory, you could also run it as a shiny app on your server, but be careful: there is no password protection. So hosting it as a publicly available shiny app seems very risky. Everybody could mess up your docker containers on the server. In contrast rstudio-server requires authentification.



