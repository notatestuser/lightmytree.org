define [
	"app"
	"lodash"
	"backbone"
	"raphael"
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
			charityIds: []
			strokes: []
			viewBoxWidth: 600
			viewBoxHeight: 500

		initialize: ->
			@charities = new Charity.Collection()
			@on 'change:strokes change:charityIds', (model) ->
				console.log "#{(model.get('strokes')).length} stroke(s)"
				model.save()

		fetch: (options = {}) ->
			oldCallback = options.success
			options.success = (model, response, options) =>
				@loadCharities()
				oldCallback? model, response, options
			super options

		loadCharities: ->
			ids = @get 'charityIds'
			@charities = new Charity.Collection ids
			@charities.reset (id: id for id in ids)

		addCharity: (model) ->
			@set 'charityIds', _.union(@get('charityIds'), [model.id])
			@charities.push model

		removeCharity: (model) ->
			@set 'charityIds', _.without(@get('charityIds'), model.id)
			@charities.remove model

	class Tree.MyModel extends Tree.Model
		url: -> "/json/my_tree"

		initialize: ->
			@remotePersist = false
			super()

		sync: (method, model, options, first = true) ->
			defaultSyncFn = ->
				Backbone.sync method, model, options

			# intercept sync() attempt with localStorage persistence
			switch method
				when "create", "update"
					res = $.jStorage.set Tree.Model.LocalStorageKey, @toJSON()
					if @remotePersist
						defaultSyncFn()
					else
						options.success model, res, options
				when "read"
					try
						model.set $.jStorage.get(Tree.Model.LocalStorageKey, {})
					catch ex
						console.error "Gracefully handling Tree.Model.sync() exception"
					if app.authed
						defaultSyncFn()
					else
						options.success model, true, options
				when "delete"
					$.jStorage.deleteKey Tree.Model.LocalStorageKey

	class Tree.Collection extends Backbone.Collection
		url: "/json/trees"
		cache: yes

		# initialize: (models, options) ->
		# 	@userId = options.userId if options and options.userId?
		# 	@url += @userId if @userId
		# 	super models, options
		# 	@fetch()

		parse: (docs) ->
			_.extend(doc, id: doc._id) for doc in docs
			# example handling of an error response from the server
			#if obj.data.message isnt 'Error' then obj.data else @models

		comparator: (tree) ->
			-new Date(tree.get 'updated_at')

	class Tree.Views.Save extends Backbone.View
		template: "tree/save"
		className: "tree-save-view"

		events:
			"click .btn-save": "save"

		save: ->
			# @$('.btn-save').button 'loading'
			@model.remotePersist = yes if app.authed
			@model.save()
			if not app.authed
				(new Modal.Views.Authenticate()).show()
			else
				app.router.go 'my_trees'

	class Tree.Views.Share extends Backbone.View
		template: "tree/share"
		className: "tree-share-view"

		serialize: ->
			@model.toJSON()

		afterRender: ->
			if app.authed
				view = new Tree.Partials.ShareLoggedIn()
				@model.remotePersist = yes
				@model.save()
			else
				view = new Tree.Partials.ShareNotLoggedIn
					model: @model
			@setView(".comment_section", view).render()

	class Tree.Partials.ShareLoggedIn extends Backbone.View
		template: "tree/share/logged_in"

	class Tree.Partials.ShareNotLoggedIn extends Tree.Views.Save # inherit save event/handling
		template: "tree/share/not_logged_in"
		className: "tree-share-notloggedin-partial"

		afterRender: ->
			@$('.alert-not-logged-in').addClass 'in'

	class Tree.Views.Intro extends Backbone.View
		template: "tree/view/intro"

		initialize: ->
			# yes, we're chaining renders because the prior one supposedly hasn't finished
			@model.on 'change', => @render => @render()

		serialize: -> @model.toJSON()

	class Tree.Views.Solo extends Backbone.View
		# template: "tree/view"
		className: "tree-view"

		afterRender: ->
			@model.on 'change', => @render()
			self = @
			$container = @$el
			# TODO store reference to Raphael canvas to prevent duplicate render bug
			new Raphael $container[0], $container.width(), $container.height(), ->
				@setViewBox 0, 0,
					self.model.get('viewBoxWidth'), self.model.get('viewBoxHeight'), true
				@add self.model.get('strokes')

	class Tree.Views.List extends Backbone.View
		tagName: "ul"
		className: "tree-list-view row-fluid"

		beforeRender: ->
			@collection.on 'reset', =>
				@render()

			# TODO: dynamically create rows to prevent padding issues?
			@collection.forEach (treeModel) ->
				treeModel.fetch
					success: (model) =>
						@insertView new Tree.Views.Item
							model: treeModel
						.render()
			, @

	class Tree.Views.Item extends Backbone.View
		template: "tree/list_item"
		tagName: "li"
		className: "mini-tree-view span4"

		serialize: -> id: @model.id

		afterRender: ->
			if @options and @options.hideButtons
				@$('.buttons').hide()

			self = @
			$container = @$el
			new Raphael $container[0], 256, 256, ->
				@setViewBox 0, 0,
					self.model.get('viewBoxWidth') or 0, self.model.get('viewBoxHeight') or 0, true
				@add self.model.get('strokes')

	Tree
