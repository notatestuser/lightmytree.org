{_}       = require 'underscore'
{parse}   = require 'url'
{inspect} = require 'util'

OpenGraph  = require 'facebook-open-graph'

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

	openGraph = new OpenGraph(config.opengraph.namespace)
	openGraphPublishLock = {}

	_ensureGraphActionPublished = (treeDoc, userDoc) ->
		console.log '_ensureGraphActionPublished()'

		# just to double check...
		return if not treeDoc.publishGraphAction or treeDoc.graph or
			not userDoc.facebook? or not treeDoc._id? or not userDoc._id? or openGraphPublishLock[treeDoc._id]

		openGraphPublishLock[treeDoc._id] = yes

		object    = config.opengraph.treeObject
		action    = config.opengraph.treeAction
		objectUrl = config.opengraph.siteBase + '/' + treeDoc._id

		console.log "Publishing graph action for #{treeDoc._id} (#{userDoc._id} #{userDoc.screenName}): #{action} #{object} #{objectUrl}"

		openGraph.publish userDoc.facebook.id, userDoc.facebook.accessToken, action, object, objectUrl, yes, (err, res) ->
			if err? or res.error?
				console.error err
				console.error res
			else if res? and typeof res is 'object'
				# just set the 'graph' attribute to the response we got; it's something like {"id":"127771810711045"}
				console.log treeDoc.graph = res

				# save the tree document
				treeDb.saveDocument treeDoc, (err, saveRes) ->
					if err?
						# try again (as it's possible the document has been revised in the meantime)
						treeDb.findById treeDoc._id, (err, treeDoc) ->
							if not err?
								treeDb.saveDocument treeDoc, (err, saveRes) ->
									console.error err if err?
							else console.error err

			delete openGraphPublishLock[treeDoc._id]

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
			treeId = decodeURIComponent og.parsedUrl.pathname.substring(1)
			treeDb.findById treeId, (err, treeRes) ->
				if treeRes and not err
					userId = treeRes.user.id
					userDb.findById userId, (err, userRes) ->
						if userRes and not err
							firstName = userRes.fullName.substring 0, userRes.fullName.indexOf(' ')
							displayName = firstName or userRes.fullName
							og.addOrSetProperty('og:title', "#{displayName}'s festive tree")
								.addOrSetProperty('og:image', config.opengraph.treeImageBase + og.parsedUrl.pathname + '.png?' + userRes._rev.substring 0, 8)
								.addOrSetProperty('og:description', "Don't try to guess #{displayName}'s dream gift this year! Instead, they'd rather you decorate their virtual tree with charitable gifts.")
								.addOrSetProperty('lightmytree:charity_count', treeRes.charityIds.length)
							network = 'twitter' if userRes.twitter?
							network = 'facebook' if userRes.facebook?
							og.addOrSetProperty('lightmytree:author', config[network].profileBaseUrl + userRes.screenName)
							donatedTotal = 0.0
							if treeRes.donationData and treeRes.donationData.length
								treeRes.donationData.forEach (donation) -> donatedTotal += parseFloat(donation.amount) if donation.amount?
							og.addOrSetProperty('lightmytree:donated_total', donatedTotal)
								.done()

							# take this opportunity to ensure we have successfully published this item to a Facebook profile
							_ensureGraphActionPublished treeRes, userRes if treeRes.publishGraphAction
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
