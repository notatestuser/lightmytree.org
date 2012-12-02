R_BUILD_FILE = ./scripts/app.build.js
COFFEE=/usr/local/bin/coffee
DATE=$(shell date +%I:%M%p)
CHECK=\033[32m✔\033[39m
HR=\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

#
# COMPILE COFFEE SOURCES
#

compile:
	echo "Compiling coffee files..."; \
	${COFFEE} -c app/*.coffee app/routes/*.coffee app/routes/helpers/*.coffee app/configs/*.coffee

#
# WATCH COFFEE FILES
#

watch:
	echo "Watching coffee files..."; \
	${COFFEE} -cw app/*.coffee app/routes/*.coffee app/routes/helpers/*.coffee app/configs/*.coffee

#
# BUILD DEPLOYABLE ASSETS
#

build:
	@echo "\n${HR}"
	@echo "Building project..."
	@echo "${HR}\n"
	r.js -o ${R_BUILD_FILE}
	@echo "Require.JS Optimization...             ${CHECK} Done"
	mv assets_live/js/libs/almond.js assets_live/js/libs/require.js
	@echo "Rename almond.js to require.js...      ${CHECK} Done"
	@echo "Successfully built at ${DATE}."
	@echo "${HR}\n"
	@echo "You're awesome."

deploy: build
	jitsu deploy

.PHONY: compile watch build deploy
