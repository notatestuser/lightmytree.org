define [
	"app",
	"modules/tree"
],

(app, Tree) ->

	# Defining the application router, you can attach sub routers here.
	Router = Backbone.Router.extend
		routes:
			"":          "index"
			":treeName": "tree"

		index: ->
			app.active = false
			app.useLayout('home_page').setViews
				".create_tree": new Tree.Views.Sketch @
				".existing_tree": new Tree.Views.List @
			.render()

		tree: (treeName) ->
			app.useLayout('tree_page').setViews
				#".trees": new Tree.Views.List(@)
			.render()

		# Shortcut for building a URL
		go: ->
			this.navigate(_.toArray(arguments).join("/"), true)

		initialize: ->
			collections =
				trees: new Tree.Collection()

			_.extend @, collections
