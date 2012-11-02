define [
	"app", "backbone", "raphael",
	"modules/charity"
	"plugins/raphael.sketchpad"
],

(app, Backbone, Raphael, Charity) ->

	Tree = app.module()

	class Tree.Model extends Backbone.Model
		@LocalStorageKey = "Tree.Model"

		defaults:
			user: null
			strokes: []
			strokeCount: 0
			charityIds: []

		initialize: ->
			@fetch()
			@loadCharities()
			@on 'change', (model) ->
				console.log "#{model.get('strokeCount')} stroke(s)"
				model.save()

		sync: (method, model, options, first = true) ->
			if not (user = @get('user')) or user.isMe()
				# intercept sync() attempt with localStorage persistence
				switch method
					when "create", "update"
						$.jStorage.set Tree.Model.LocalStorageKey, @toJSON()
					when "read"
						try
							model.set $.jStorage.get(Tree.Model.LocalStorageKey, {})
						catch ex
							console.error "Gracefully handling Tree.Model.sync() exception"
					when "delete"
						$.jStorage.deleteKey Tree.Model.LocalStorageKey
			super method, model, options, false if user

		loadCharities: ->
			ids = @get('charityIds')
			@charities = new Charity.Collection ids

	class Tree.Collection extends Backbone.Collection
		url: -> "/api/trees/" + @user
		cache: yes

		parse: (obj) ->
			if obj.data.message isnt 'Error' then obj.data else @models

		initialize: (models, options) ->
			@user = options.user if options and options.user?

		comparator: (tree) ->
			-new Date(tree.get 'updated_at')

	class Tree.Views.Sketch extends Backbone.View
		template: "tree/sketch"
		className: "sketchpad-view"

		resizeCanvas: ->
			if @$container
				console.log "New canvas dimensions: #{@$container.width()} #{@$container.height()}"
				@sketchpad.paper().setSize @$container.width(), @$container.height()

		afterRender: ->
			self = @
			$container = @$container = @$('.sketchpad-editor')
			new Raphael $container[0], $container.width(), $container.height(), ->
				sketchpad = self.sketchpad = Raphael.sketchpad @,
					strokes: self.model.get('strokes')
				sketchpad.change ->
					self.model.set
						strokes: strokes = sketchpad.strokes()
						strokeCount: strokes.length

				# bind resize handler here in lieu of watching the element itself
				$(window).resize self.resizeCanvas.bind(self)

	class Tree.Views.Save extends Backbone.View
		template: "tree/save"
		className: "tree-save-view"

	class Tree.Views.Solo extends Backbone.View
		template: "tree/view"
		className: "tree-view"

	class Tree.Views.List extends Backbone.View
		template: "tree/list"
		tagName: "ul"
		className: "trees-view"

	class Tree.Views.Item extends Backbone.View
		template: "tree/list_item"
		tagName: "li"
		className: "mini-tree-view"


	Tree
