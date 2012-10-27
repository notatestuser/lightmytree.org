define [
	"app"
],

(app) ->

	# Defining the application router, you can attach sub routers here.
	Router = Backbone.Router.extend
		routes:
			"":					 "index"
			":treeName": "tree"

		index: ->
			alert 'index'

		tree: (treeName) ->
			alert 'tree ' + treeName
