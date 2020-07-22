# get shiny serves plus tidyverse packages image
FROM rocker/shiny-verse:3.6.3

# system libraries of general use
RUN apt-get update && apt-get install -y build-essential

# install R packages required
# (change it dependeing on the packages you need)
RUN R -e "pkg <- c('dplyr', 'dbplyr', 'ggplot2', 'maps', 'DBI', 'RSQLite', 'shiny'); \
           install.packages(pkg, repos = \
           'http://mran.revolutionanalytics.com/snapshot/2020-05-28/')"

# create folder to store data
RUN rm -rf /srv/shiny-server/*
RUN mkdir -p /srv/shiny-server/

# copy the app to the image
COPY app.R /srv/shiny-server/
COPY bien.db /srv/shiny-server/

# this file needs to be executable.
# dont forget: `sudo chmod +x shiny-server.sh`
COPY shiny-server.sh /usr/bin/shiny-server.sh

# select port
EXPOSE 3838

# run app
CMD ["/usr/bin/shiny-server.sh"]
