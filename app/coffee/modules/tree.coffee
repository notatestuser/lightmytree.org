define [
	"app", "lodash",
	"backbone", "raphael",
	"modules/charity"
	"modules/modal"
	"plugins/raphael.sketchpad"
],

(app, _, Backbone, Raphael, Charity, Modal) ->

	Tree = app.module()

	class Tree.Model extends Backbone.Model
		@LocalStorageKey = "Tree.Model"

		defaults:
			user: null
			strokes: []
			charityIds: []

		initialize: ->
			@fetch()
			@loadCharities()
			@on 'change:strokes change:charityIds', (model) ->
				console.log "#{(model.get('strokes')).length} stroke(s)"
				model.save()

		sync: (method, model, options, first = true) ->
			defaultSyncFn = ->
				Backbone.sync method, model, options

			# intercept sync() attempt with localStorage persistence
			switch method
				when "create", "update"
					$.jStorage.set Tree.Model.LocalStorageKey, @toJSON()
					defaultSyncFn() if @remotePersist
				when "read"
					try
						model.set $.jStorage.get(Tree.Model.LocalStorageKey, {})
					catch ex
						console.error "Gracefully handling Tree.Model.sync() exception"
					defaultSyncFn() if app.authed
				when "delete"
					$.jStorage.deleteKey Tree.Model.LocalStorageKey

		loadCharities: ->
			ids = @get('charityIds')
			@charities = new Charity.Collection ids

		addCharity: (model) ->
			console.log "added charity to Tree.Model"
			@set 'charityIds', _.union(@get('charityIds'), [model.id])
			@charities.push model

		removeCharity: (model) ->
			console.log "removing charity from Tree.Model"
			@set 'charityIds', _.without(@get('charityIds'), model.id)
			@charities.remove model

	class Tree.MyModel extends Tree.Model
		url: -> "/json/my_tree"

		initialize: ->
			@remotePersist = false
			super()

	class Tree.Collection extends Backbone.Collection
		url: "/json/trees/"
		cache: yes

		initialize: (models, options) ->
			@userId = options.userId if options and options.userId?
			@url += @userId if @userId
			super models, options
			@fetch()

		parse: (docs) ->
			(_.extend(doc, id: doc._id) for doc in docs)
			# example handling of an error response from the server
			#if obj.data.message isnt 'Error' then obj.data else @models

		comparator: (tree) ->
			-new Date(tree.get 'updated_at')

	class Tree.Views.Sketch extends Backbone.View
		template: "tree/sketch"
		className: "sketchpad-view"

		resizeCanvas: ->
			if @$container
				console.log "New canvas dimensions: #{@$container.width()} #{@$container.height()}"
				@sketchpad.paper().setSize @$container.width(), @$container.height()

		showSavedAlert: ->
			if not @shownSavedAlert
				@shownSavedAlert = yes
				@$('.alert-saved-container')
					.fadeIn('slow')
					.slideDown('slow')

		afterRender: ->
			self = @
			$container = @$container = @$('.sketchpad-editor')
			new Raphael $container[0], $container.width(), $container.height(), ->
				sketchpad = self.sketchpad = Raphael.sketchpad @,
					strokes: self.model.get('strokes')
				sketchpad.change ->
					self.model.set strokes: strokes = sketchpad.strokes()
					self.showSavedAlert()

				# bind resize handler here in lieu of watching the element itself
				$(window).resize self.resizeCanvas.bind(self)

	class Tree.Views.Save extends Backbone.View
		template: "tree/save"
		className: "tree-save-view"

		events:
			"click .btn-save": "save"

		save: ->
			@model.remotePersist = yes if app.authed
			@model.save()
			(new Modal.Views.Authenticate()).show() if not app.authed

	class Tree.Views.Solo extends Backbone.View
		template: "tree/view"
		className: "tree-view"

	class Tree.Views.List extends Backbone.View
		template: "tree/list"
		tagName: "ul"
		className: "tree-list-view"

		beforeRender: ->
			@collection.on 'reset', =>
				@render()

			@collection.forEach (treeModel) ->
				view = new Tree.Views.Item
					model: treeModel
				@insertView view
			, @

	class Tree.Views.Item extends Backbone.View
		template: "tree/list_item"
		tagName: "li"
		className: "mini-tree-view"

		afterRender: ->
			self = @
			$container = @$el
			new Raphael $container[0], 256, 256, ->
				# sketchpad = self.sketchpad = Raphael.sketchpad @,
				# 	strokes: self.model.get('strokes')
				# 	width: 256
				# 	height: 256
				# .editing false
				@add self.model.get('strokes')
				@setViewBox 0, 0, 617, 498, true


	Tree
