define [
	"app",
	"backbone"
],

(app, Backbone) ->

	Tree = app.module()

	Tree.Collection = Backbone.Collection.extend
		url: -> "/api/trees/" + @user

		cache: yes

		parse: (obj) ->
			if obj.data.message isnt 'Error' then obj.data else @models

		initialize: (models, options) ->
			@user = options.user if options

		comparator: (tree) ->
			-new Date(tree.get 'updated_at')

	Tree.Views.Sketch = Backbone.View.extend
		template: "tree/sketch"

		className: "sketchpad-wrapper"

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
