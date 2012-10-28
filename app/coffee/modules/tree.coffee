define [
	"app",
	"backbone",
	"raphael",
	"plugins/raphael.sketchpad"
],

(app, Backbone, Raphael) ->

	Tree = app.module()

	Tree.Model = Backbone.Model.extend
		defaults:
			user: null
			strokes: []
			strokeCount: 0

		initialize: ->
			@on 'change', (model) ->
				console.log model.get('strokeCount')

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
		className: "sketchpad-wrapper"

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
		className: "tree-wrapper"

	Tree.Views.List = Backbone.View.extend
		template: "tree/list"
		tagName: "ul"
		className: "trees-wrapper"

	Tree.Views.Item = Backbone.View.extend
		template: "tree/list_item"
		tagName: "li"
		className: "mini-tree-wrapper"

	Tree
