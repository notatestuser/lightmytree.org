# Application.
define [
	"jquery", "lodash", "backbone",
	"plugins/backbone.layoutmanager"
],

($, _, Backbone) ->

	app =
		root: '/'

	# Localize or create a new JavaScript Template object.
	app.templates ||= window.JST ||= {}

	# Configure LayoutManager with Backbone Boilerplate defaults.
	Backbone.LayoutManager.configure
		# Allow LayoutManager to augment Backbone.View.prototype.
    manage: true

		prefix: "app/templates/"

		fetch: (path) ->
			path += ".html"

			return app.templates[path] if app.templates[path]?

			done = @async()

			$.get app.root + path, (contents) ->
				done(app.templates[path] = _.template contents)

			app.templates[path]


	# Mix Backbone.Events, modules, and layout management into the app object.
	_.extend app,
		# Create a custom object with a nested Views object.
		module: (additionalProps) ->
			_.extend
				Views: {}
			, additionalProps

		# Helper for using layouts.
		useLayout: (name) ->
			# If already using this Layout, then don't re-inject into the DOM.
			return @layout	if @layout and @layout.options.template is name

			# If a layout already exists, remove it from the DOM.
			@layout.remove()	if @layout

			# Create a new Layout.
			layout = new Backbone.Layout(
				template: name
				className: "layout " + name
				id: "layout"
			)

			# Insert into the DOM.
			$("#main").empty().append layout.el

			# Render the layout.
			layout.render()

			# Cache the refererence.
			@layout = layout

			# Return the reference, for chainability.
			layout

	, Backbone.Events

	app

