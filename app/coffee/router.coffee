define [
	"app",
	"modules/tree",
	"modules/charity"
],

(app, Tree, Charity) ->

	# Defining the application router, you can attach sub routers here.
	Router = Backbone.Router.extend
		routes:
			"":               "index"
			"sketch":         "sketch"
			"tree/:treeName": "tree"

		index: ->
			app.active = false
			app.useLayout('home_page').setViews
				#".create_tree": new Tree.Views.Sketch @
				".existing_tree": new Tree.Views.List @
			.render()

		sketch: ->
			app.useLayout('sketch_page').setViews
				".sketchpad": new Tree.Views.Sketch
					model: @newTree
				".charity_picker": new Charity.Views.Picker
					collection: @recentCharities
			.render()

		tree: (treeName) ->
			app.useLayout('tree_page').setViews({})
				#".trees": new Tree.Views.List(@)
			.render()

		# Shortcut for building a URL
		go: ->
			this.navigate(_.toArray(arguments).join("/"), true)

		initialize: ->
			models =
				user: null # get authed user model here
				newTree: new Tree.Model()
				myTrees: new Tree.Collection()
				recentCharities: new Charity.RecentCharitiesCollection()

			_.extend @, models
