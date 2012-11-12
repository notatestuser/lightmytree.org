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
		url: -> "/json/users/" + (@get('_id') or '')

		defaults:
			screenName: 'Unknown'
			fullName: 'Unknown'
			imageUrl: ''
			treeIds: []

		initialize: ->
			@trees = new Tree.Collection()
			@fetch
				success: =>
					console.log "User.Model authenticated as #{@get('screenName')}"
					@loadTrees()

		loadTrees: ->
			ids = @get 'treeIds'
			@trees.reset (id: id for id in ids)

	User
