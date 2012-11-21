{_}       = require 'underscore'
{parse}   = require 'url'
{inspect} = require 'util'

{TreeDatabase, UserDatabase} = require './database'

class OpengraphProperties
	properties: {}

	constructor: (@request) ->
		@url = @request.url
		@parsedUrl = parse(@url)
		@matched = no
		@doneCount = 0

	isRequestFor: (path) ->
		test = @parsedUrl.pathname.indexOf(path) is 0
		@matched = yes if test
		test

	isRequestUnmatched: -> not @matched

	expect: (@expected, @callback) ->

	done: ->
		if ++@doneCount is @expected
			process.nextTick =>
				@callback()

	addOrSetProperty: (property, content) ->
		@properties[property] = content
		@

module.exports = (app, config) ->

	userDb = new UserDatabase config
	treeDb = new TreeDatabase config

	_makeBaseOg = (request) ->
		og = new OpengraphProperties(request)
			.addOrSetProperty('fb:app_id', config.facebook.appId)
			.addOrSetProperty('og:site_name', config.opengraph.siteName)
			.addOrSetProperty('og:image', config.opengraph.defaultImage)
			.addOrSetProperty('og:url', config.opengraph.siteBase + request.url)
			.addOrSetProperty('og:description', 'Draw a virtual Christmas tree, share it with friends and receive donations in lieu of physical gifts. Ask for a better kind of gift this Christmas.')

	_addSketchPageProperties = (og) ->
		if og.isRequestFor '/sketch'
			og.addOrSetProperty('og:title', 'Sketch a tree')
			og.addOrSetProperty('og:description', 'Draw your own charitable Christmas scene on LightMyTree')
		og.done()

	_addMyTreesPageProperties = (og) ->
		if og.isRequestFor '/my_trees'
			og.addOrSetProperty('og:title', 'My trees')
			og.addOrSetProperty('og:description', 'See all of the drawings you have submitted to LightMyTree.')
		og.done()

	_addTreePageProperties = (og) ->
		if og.isRequestUnmatched()
			og.addOrSetProperty('og:type', 'lightmytree:tree')
			treeDb.findById og.parsedUrl.pathname.substring(1), (err, res) ->
				if res and not err
					userId = res.user.id
					userDb.findById userId, (err, res) ->
						if res and not err
							og.addOrSetProperty('og:title', "#{res.fullName}'s festive scene")
								.addOrSetProperty('og:image', config.opengraph.treeImageBase + og.parsedUrl.pathname + '.png?' + res._rev.substring 0, 8)
								.addOrSetProperty('og:description', "Don't try to guess #{res.fullName}'s dream gift this year! Instead, they'd rather you decorate their virtual tree with charitable gifts.")
								.done()
						else
							og.done()
				else
					og.done()
		else
			og.done()

	_getOgForPage = (request, callback) ->
		og = _makeBaseOg request
		og.expect 3, callback
		_addSketchPageProperties og
		_addMyTreesPageProperties og
		_addTreePageProperties og
		og

	(callback) ->
		(req, res) ->
			og = _getOgForPage req, ->
				callback req, res, og.properties
