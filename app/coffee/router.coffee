define [
	"app"
	"modules/tree"
	"modules/charity"
	"modules/sketch"
	"modules/modal"
],

(app, Tree, Charity, Sketch, Modal) ->

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
				_newTree: newTree = new Tree.MyModel()
				_myTrees: new Tree.Collection null, '' # will return our stuff if authed
				_recentCharities: new Charity.RecentCharitiesCollection()
				_typeaheadCharities: new Charity.TypeaheadCollection()
				_sketch: new Sketch.Model
					tree: newTree

			_.extend @, models

		index: ->
			app.active = false
			app.useLayout('home_page').setViews
				#".create_tree": new Tree.Views.Sketch @
				".existing_tree": new Tree.Views.List @
			.render()

		sketch: ->
			app.useLayout('sketch_page').setViews
				".sketchpad": new Sketch.Views.Workspace
					model: @_sketch
					views:
						".sketchpad-editor": new Sketch.Views.Sketchpad
							model: @_sketch
						".sketchpad-tools-left": new Sketch.Views.Toolkit
							model: @_sketch
							pencilFloat: 'right'
							views:
								".eraser-panel": new Sketch.Views.EraserPanel
									model: @_sketch
						".sketchpad-tools-right": new Sketch.Views.Toolkit
							model: @_sketch
							pencilFloat: 'left'
				".charity_picker": new Charity.Views.Picker
					collection: @_recentCharities
					treeModel: @_newTree
					typeaheadCharities: @_typeaheadCharities
				".save": new Tree.Views.Save
					model: @_newTree
				".authenticate_modal": new Modal.Views.Authenticate
			.render()

		tree: (treeName) ->
			app.useLayout('tree_page').setViews({})
				#".trees": new Tree.Views.List(@)
			.render()

		myTrees: ->
			app.useLayout('my_trees_page').setViews
				".share_my_tree": new Tree.Views.Share
					model: @_newTree
					views:
						".share_preview": new Tree.Views.Item
							model: @_newTree
				".my_trees": new Tree.Views.List
					collection: @_myTrees
				".authenticate_modal": new Modal.Views.Authenticate
			.render()

		# Shortcut for building a URL
		go: ->
			this.navigate(_.toArray(arguments).join("/"), true)

