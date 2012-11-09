define [
	"app",
	"modules/tree",
	"modules/charity",
	"modules/modal"
],

(app, Tree, Charity, Modal) ->

	# Defining the application router, you can attach sub routers here.
	Router = Backbone.Router.extend
		routes:
			"":               "index"
			"sketch":         "sketch"
			"tree/:treeName": "tree"
			"my_trees":       "myTrees"

		initialize: ->
			models =
				user: null # get authed user model here
				newTree: new Tree.MyModel()
				myTrees: new Tree.Collection null, '' # will return our stuff if authed
				recentCharities: new Charity.RecentCharitiesCollection()
				typeaheadCharities: new Charity.TypeaheadCollection()

			_.extend @, models

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
					treeModel: @newTree
					typeaheadCharities: @typeaheadCharities
				".save": new Tree.Views.Save
					model: @newTree
				".authenticate_modal": new Modal.Views.Authenticate
			.render()

		tree: (treeName) ->
			app.useLayout('tree_page').setViews({})
				#".trees": new Tree.Views.List(@)
			.render()

		myTrees: ->
			app.useLayout('my_trees_page').setViews
				".share_my_tree": new Tree.Views.Share
					model: @newTree
					views:
						".share_preview": new Tree.Views.Item
							model: @newTree
				".my_trees": new Tree.Views.List
					collection: @myTrees
				".authenticate_modal": new Modal.Views.Authenticate
			.render()

		# Shortcut for building a URL
		go: ->
			this.navigate(_.toArray(arguments).join("/"), true)

