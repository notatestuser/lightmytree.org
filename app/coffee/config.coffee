# Set the require.js configuration for your application.
require.config

	# Initialize the application with the main application file.
	deps: ["main"]

	paths:

		# JavaScript folders.
		libs: "../js/libs"

		#plugins: "../js/plugins",

		# Libraries.
		jquery: "../js/libs/jquery"
		lodash: "../js/libs/lodash"
		backbone: "../js/libs/backbone"
		raphael: "../js/libs/raphael"
		eve: "../js/libs/eve"

	shim:

		# Backbone library depends on lodash and jQuery.
		backbone:
			deps: ["lodash", "jquery"]
			exports: "Backbone"

		# Eve is required by Raphael for internal namespacing
		eve:
			exports: "eve"

		raphael:
			# Eve is required by Raphael for internal namespacing
			deps: ["eve"]
			exports: "Raphael"

		"plugins/bootstrap": ["jquery"]

		# Backbone.LayoutManager depends on Backbone.
		"plugins/backbone.layoutmanager": ["backbone"]

		"plugins/raphael.sketchpad":
			deps: ["raphael"]
			exports: "Raphael.sketchpad"
