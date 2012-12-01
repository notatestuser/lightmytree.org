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

		initialize: (attributes = {}) ->
			@trees = attributes.myTreesCollection
			super attributes
			@_findFirstName()
			@on 'change:fullName', @_findFirstName, @

		fetch: (options = {}) ->
			options.success = => @loadTrees()
			super options
			@

		loadTrees: ->
			ids = @get 'treeIds'
			@trees.reset (id: id for id in ids)

		_findFirstName: ->
			firstName = @get 'fullName'
			if firstName and (firstSpaceIdx = firstName.indexOf ' ') isnt -1
				firstName = firstName.substring 0, firstSpaceIdx
			@set 'firstName', firstName

	class User.Collection extends Backbone.Collection
		url: "/json/users"
		cache: yes

	User
