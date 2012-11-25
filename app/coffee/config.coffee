###
 * LightMyTree Application Bootstrapper
 * Copyright (c) 2012 Luke Plaster (notatestuser@gmail.com)
###

# Set the require.js configuration for your application.
require.config

	# Initialize the application with the main application file.
	deps: ["main"]

	paths:

		# JavaScript folders.
		libs: "../js/libs"

		#plugins: "../js/plugins",

		# Libraries.
		jquery: "libs/jquery"
		lodash: "libs/lodash"
		backbone: "libs/backbone"
		raphael: "libs/raphael"
		eve: "libs/eve"
		bootstrap: "libs/bootstrap"

	shim:

		# Backbone library depends on lodash and jQuery.
		backbone:
			deps: ["lodash", "jquery"]
			exports: "Backbone"

		# Backbone.LayoutManager depends on Backbone.
		"plugins/backbone.layoutmanager": ["backbone"]

		"plugins/raphael.sketchpad":
			deps: ["raphael"]
			exports: "Raphael.sketchpad"

		# Bootstrap Javascript components
		"bootstrap/bootstrap-affix":		 ["jquery"]
		"bootstrap/bootstrap-alert":		 ["jquery", "bootstrap/bootstrap-transition"]
		"bootstrap/bootstrap-button":		 ["jquery", "bootstrap/bootstrap-transition"]
		"bootstrap/bootstrap-carousel":	 ["jquery"]
		"bootstrap/bootstrap-collapse":	 ["jquery"]
		"bootstrap/bootstrap-dropdown":	 ["jquery"]
		"bootstrap/bootstrap-modal":		 ["jquery", "bootstrap/bootstrap-transition"]
		"bootstrap/bootstrap-popover":	 ["jquery", "bootstrap/bootstrap-tooltip"]
		"bootstrap/bootstrap-scrollspy":	 ["jquery"]
		"bootstrap/bootstrap-tab":			 ["jquery"]
		"bootstrap/bootstrap-tooltip":	 ["jquery", "bootstrap/bootstrap-transition"]
		"bootstrap/bootstrap-transition": ["jquery"]
		"bootstrap/bootstrap-typeahead":	 ["jquery", "bootstrap/bootstrap-transition"]

		# Eve is required by Raphael for internal namespacing
		eve:
			exports: "eve"

		raphael:
			deps: ["eve"]
			exports: "Raphael"

		"plugins/jquery.xdomainrequest":		["jquery"]
		"plugins/jquery.json-2.3.min":		["jquery"] # for jstorage
		"plugins/jquery.jstorage":				["jquery"]
		"plugins/jquery.sharrre-1.3.4.min":	["jquery"]

