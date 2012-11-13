define [
	"app",
	"lodash",
	"backbone",
	"modules/tree"
],

(app, _, Backbone, Tree) ->

	User = app.module()

	class User.Model extends Backbone.Model
		idAttribute: '_id'
		urlRoot: "/json/users"

		defaults:
			screenName: 'Unknown'
			fullName: 'Unknown'
			imageUrl: ''
			treeIds: []

		initialize: (attributes) ->
			@trees = new Tree.Collection()
			super attributes

		fetch: (options = {}) ->
			options.success = => @loadTrees()
			super options
			@

		loadTrees: ->
			ids = @get 'treeIds'
			@trees.reset (id: id for id in ids)

	class User.Collection extends Backbone.Collection
		url: "/json/users"
		cache: yes

	User
