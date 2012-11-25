###
 * LightMyTree Application Module
 * Copyright (c) 2012 Luke Plaster (notatestuser@gmail.com)
###

# Application.
define [
	"jquery", "lodash", "backbone"
	"plugins/jquery.xdomainrequest"
	"plugins/jquery.json-2.3.min"
	"plugins/jquery.jstorage"
	"plugins/backbone.layoutmanager"
],

($, _, Backbone) ->

	app =
		root: '/'

	# Prepare to fetch client configuration
	initDeferred = $.get app.root + 'json/client_init', (data) ->
		_.extend(app, data)
	, 'json'

	# This simple function will allow higher-level layers to request a URL and only sync when it has arrived
	app.waitForUrl = (key, callback) ->
		callbackFn = ->
			callback eval app.urls[key]
		if initDeferred.state() is 'resolved'
			callbackFn()
		else
			initDeferred.then callbackFn

	app.getUrlFn = (key) ->
		eval app.urls[key]

	app.authRedirect = (provider) ->
		window.location.href = "/auth/#{provider}"


	# Localize or create a new JavaScript Template object.
	app.templates ||= window.JST ||= {}

	# Configure LayoutManager with Backbone Boilerplate defaults.
	Backbone.LayoutManager.configure
		# Allow LayoutManager to augment Backbone.View.prototype.
		manage: true

		#prefix: "templates/"

		paths:
			layout: "templates/layouts/"
			template: "templates/"

		fetch: (path) ->
			path += ".html"

			return app.templates[path] if typeof app.templates[path] is 'function'

			done = @async()

			if app.templates[path]?
				app.templates[path].then ->
					done app.templates[path]
			else
				app.templates[path] = $.Deferred()

				$.get app.root + path, (contents) ->
					deferred = app.templates[path]
					app.templates[path] = _.template contents
					deferred.resolve()

					# wait for client_init to have been completed before we begin rendering views
					if initDeferred.state() is 'resolved'
						done app.templates[path]
					else
						initDeferred.then done.bind(@, app.templates[path])

			app.templates[path]


	# Mix Backbone.Events, modules, and layout management into the app object.
	_.extend app,
		# Create a custom object with a nested Views object.
		module: (additionalProps) ->
			_.extend
				Views: {}
				Partials: {}
			, additionalProps

		# Helper for using layouts.
		useLayout: (name, options) ->
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

