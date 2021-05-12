.DEFAULT_GOAL := help

DOCKER_IMAGE := kguidonimartins/check-trait-sampling-location-bien

all: get-bien-data create-db run ## run create-db and run targets

run:  ## run shiny app locally
	xdg-open http://127.0.0.1:8080/
	Rscript -e "shiny::runApp(appDir = '.', port = 8080, quiet = TRUE)"

get-bien-data:   ## download trait data from bien
ifeq (,$(wildcard ./data/all_traits_from_bien.csv))
	@echo "Downloading data from BIEN"
	Rscript -e "source('get-intraspecific-trait-data.R')"
else
	@echo "trait data already exists! exit."
endif

create-db: get-bien-data ## create db based on csv
ifeq (,$(wildcard ./bien.db))
	@echo "Creating db"
	python create_db.py
else
	@echo "db already exists! exit."
endif

styler:
	Rscript -e "styler::style_file('app.R')"
	Rscript -e "styler::style_file('get-intraspecific-trait-data.R')"

docker_build: styler ## build the docker image based on Dockerfile
	docker build -t $(DOCKER_IMAGE) .

docker_run:   ## run the docker container
	xdg-open http://127.0.0.1:3838/
	docker run --rm -p 3838:3838 $(DOCKER_IMAGE)

docker_push:  ## push docker image to dockerhub
	docker login && docker push $(DOCKER_IMAGE)

help:         ## show this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

