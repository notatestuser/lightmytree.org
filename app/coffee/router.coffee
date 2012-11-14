define [
	"app"
	"modules/user"
	"modules/tree"
	"modules/charity"
	"modules/sketch"
	"modules/modal"
],

(app, User, Tree, Charity, Sketch, Modal) ->

	# Defining the application router, you can attach sub routers here.
	Router = Backbone.Router.extend
		routes:
			"":               "index"
			"sketch":         "sketch"
			"my_trees":       "myTrees"
			":treeName":      "tree" # pending change to /trees/%s/1 ?
			"*other":         "show404"

		initialize: ->
			models =
				_user: me = (new User.Model()).fetch() # will fetch authed user from server
				_newTree: newTree = new Tree.MyModel()
				_myTrees: me.trees # will return our stuff if authed
				_otherTrees: new Tree.Collection()
				_otherUsers: new User.Collection()
				_recentCharities: new Charity.RecentCharitiesCollection()
				_typeaheadCharities: new Charity.TypeaheadCollection()
				_sketch: new Sketch.Model( tree: newTree )
			_.extend @, models

		index: ->
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

		tree: (treeId) ->
			# grab the cached tree or fetch one
			treeModel = @_otherTrees.get treeId
			unless treeModel
				@_otherTrees.add treeModel = new Tree.Model(id: treeId)
				treeModel.fetch
					error: => @show404()

			userModel = @_otherUsers.get treeId
			unless userModel
				# this should resolve with the tree's ID as our Couch byId view takes them into account...
				@_otherUsers.add userModel = new User.Model(_id: treeId) # how consistent...
				userModel.fetch
					error: => @show404()

			app.useLayout('tree_page').setViews
				".row-intro": new Tree.Views.Intro
					model: userModel
				".sketchpad-editor": new Tree.Views.Solo
					model: treeModel
			.render()

		myTrees: ->
			app.useLayout('my_trees_page').setViews
				".share_my_tree": new Tree.Views.Share
					model: @_newTree
					views:
						".share_preview": new Tree.Views.Item
							model: @_newTree
							hideButtons: yes
				".my_trees": new Tree.Views.List
					collection: @_myTrees
				".authenticate_modal": new Modal.Views.Authenticate
			.render()

		show404: ->
			@go()
			$('#modal-404').modal()

		# Shortcut for building a URL
		go: ->
			this.navigate(_.toArray(arguments).join("/"), true)

