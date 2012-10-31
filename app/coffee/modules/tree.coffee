define [
	"app", "backbone", "raphael",
	"modules/charity"
	"plugins/raphael.sketchpad"
],

(app, Backbone, Raphael, Charity) ->

	Tree = app.module()

	Tree.Model = Backbone.Model.extend
		defaults:
			user: null
			strokes: []
			strokeCount: 0
			charityIds: []

		initialize: ->
			@loadCharities()
			@on 'change', (model) ->
				console.log "#{model.get('strokeCount')} stroke(s)"

		loadCharities: ->
			ids = @get('charityIds')
			@charities = new Charity.Collection ids

	Tree.Collection = Backbone.Collection.extend
		url: -> "/api/trees/" + @user
		cache: yes

		parse: (obj) ->
			if obj.data.message isnt 'Error' then obj.data else @models

		initialize: (models, options) ->
			@user = options.user if options and options.user?

		comparator: (tree) ->
			-new Date(tree.get 'updated_at')

	Tree.Views.Sketch = Backbone.View.extend
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
				sketchpad = self.sketchpad = Raphael.sketchpad @
				sketchpad.change ->
					self.model.set
						strokes: strokes = sketchpad.strokes()
						strokeCount: strokes.length

				# bind resize handler here in lieu of watching the element itself
				$(window).resize self.resizeCanvas.bind(self)

	Tree.Views.Solo = Backbone.View.extend
		template: "tree/view"
		className: "tree-view"

	Tree.Views.List = Backbone.View.extend
		template: "tree/list"
		tagName: "ul"
		className: "trees-view"

	Tree.Views.Item = Backbone.View.extend
		template: "tree/list_item"
		tagName: "li"
		className: "mini-tree-view"

	Tree
