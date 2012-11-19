{_}       = require 'underscore'
{inspect} = require 'util'
{TreeDatabase, UserDatabase} = require '../database'
JustGiving = require './helpers/justgiving'

module.exports = (app, config) ->

	console.log "Defining DATA routes"

	userDb = new UserDatabase config
	treeDb = new TreeDatabase config

	jg = config.justgiving
	charityService = new JustGiving jg.siteUrl, jg.apiUrl, jg.apiKey

	recentCharities = []


	#
	# some helper functions
	#

	withAuth = (callback) ->
		(req, res) ->
			return callback(req, res, req.user._id) if req.user? and req.user._id?
			callback req, res

	ensureAuth = (callback) ->
		(req, res) ->
			if not req.user? or not req.user._id?
				res.send "Please authenticate", 401
			else
				callback req, res, req.user._id, req.user

	sendDatabaseError = (err, res) ->
		console.error "ERROR: sendDatabaseError()\n" + inspect(err)
		console.trace 'sendDatabaseError'
		res.send "Database error", 500

	wrapError = (res, callback) ->
		(err, doc) ->
			if err
				sendDatabaseError err, res
			else
				callback? doc


	#
	# here come our service route handlers
	#

	# /json/typeahead_charities
	app.get "/json/typeahead_charities/:query", (req, res) ->
		if req.params.query? and req.params.query.length > 2
			query = req.params.query
			charityService.charitySearch query, 8, 1, wrapError res, (docs) ->
				results = docs.charitySearchResults or []
				res.json _.pluck(results, 'name')

				# if we have results, update our array of recentCharities
				if results.length
					recentCharities =
						_.chain(recentCharities)
						 .union(_.first(results, 4))
						 .last(4)
						 .value()
		else
			res.send "More query data required", 500

	# /json/recent_charities
	app.get "/json/recent_charities", (req, res) ->
		res.json _.first(recentCharities, 4)

	# /json/my_tree
	myTreeFn = ensureAuth (req, res, userId) ->
		data = req.body

		createOrUpdateFn = ->
			# get the current user's document
			userDb.findById userId, (err, userDoc) ->
				if not err
					treeDb.createOrUpdate userDoc, data, (err, treeRes) ->
						sendDatabaseError err, res if err

						# add tree ID to user object and save it
						if treeRes and not err
							treeIds = userDoc.treeIds or userDoc.treeIds = []
							treeIds.push treeRes.id if treeIds.indexOf(treeRes.id) is -1
							userDb.saveDocument userDoc, (err, userRes) ->
								sendDatabaseError err, res if err
								res.json id: treeRes.id if treeRes

						else res.send "Unknown error", 500
				else
					sendDatabaseError err, res

		# if an ID is being provided, ensure the target tree belongs to this user
		if data.id? and data.id.length?
			treeDb.findById data.id, (err, doc) ->
				if doc and doc.user.id isnt req.user._id
					console.error "ERROR: attempt to sabotage another user's tree"
					console.error "(user: #{userId}, target ID: #{data.id})"
					res.send "Unauthorised", 401
				else
					if not doc
						console.error "ERROR: tree `#{data.id}` doesn't exist but referenced by `#{userId}`; removing ID"
						delete data.id
					createOrUpdateFn()
		else
			createOrUpdateFn()
	app.post "/json/my_tree", myTreeFn
	app.put "/json/my_tree", myTreeFn

	# /json/users/:userId
	app.get /^\/json\/users\/?([a-zA-Z0-9_.-]+)?$/, withAuth (req, res, userId) ->
		id = req.params[0] or userId
		if id
			userDb.findById req.params[0] or userId, (err, doc) ->
				sendDatabaseError(err, res) if err
				res.json _.omit(doc, UserDatabase.PrivateFields) if doc
				res.send "Not found", 404 if not doc
		else
			res.send "Please authenticate or supply a user ID", 401

	# /json/trees/:id
	app.get /^\/json\/trees\/?([a-zA-Z0-9_.-]+)?$/, (req, res) ->
		if req.params[0]
			treeDb.findById req.params[0], (err, doc) ->
				if err
					sendDatabaseError(err, res)
				else
					res.json(doc) if doc
					res.send "Not found", 404 if not doc
		else
			res.send "Not found", 404

	# /json/trees/:id/donate
	donateFn = (req, res) ->
		data = req.body
		treeId = req.params[0] if req.params?

		if treeId and data
			treeDb.findById treeId, wrapError res, (treeDoc) ->
				if not treeDoc
					res.send "Not found", 404
				else
					donation = _.pick data, 'charityId', 'name', 'message', 'gift', 'giftDropX', 'giftDropY'
					donation.treeId = treeId
					if Object.keys(donation).length isnt 7
						res.send "More data required", 500
					else
						try
							ourRef = new Buffer(JSON.stringify donation).toString 'base64'
							res.json
								id: (new Date()).getTime()
								redirectUrl: charityService.getDonationUrl donation.charityId, jg.callbackUrl, ourRef
						catch err
							res.send err, 500
		else
			res.send "Not found", 404
	app.post /^\/json\/trees\/([a-zA-Z0-9_.-]+)\/donations$/, donateFn
	app.put /^\/json\/trees\/([a-zA-Z0-9_.-]+)\/donations$/, donateFn

	# /callback/jg?id=<JUSTGIVING-DONATION-ID>&data=<our encoded json>
	# e.g. http://dev.lightmytree.org:3000/callback/jg?id=35496621&data=eyJjaGFyaXR5SWQiOiIxODY2ODUiLCJuYW1lIjoiIiwibWVzc2FnZSI6IiIsImdpZnQiOiJnaWZ0LTEiLCJnaWZ0RHJvcFgiOjE3OC40LCJnaWZ0RHJvcFkiOjMzMy40fQ==
	app.get "/callback/jg", (req, res) ->
		if req.query.id? and req.query.data?
			try
				decodedData = JSON.parse(new Buffer(req.query.data, 'base64').toString 'utf8')
			catch err
				return res.send err, 500
			console.log decodedData
			donation = _.pick decodedData, 'charityId', 'name', 'message', 'gift', 'giftDropX', 'giftDropY'
			if decodedData.treeId? and Object.keys(donation).length is 6
				charityService.getDonationStatus req.query.id, wrapError res, (statusData) ->
					treeDb.findById decodedData.treeId, wrapError res, (treeDoc) ->
						if not treeDoc
							res.send "Tree record not found", 404
						else
							donations = treeDoc.donationData ?= []
							found = _.where donations,
								id: statusData.id
							if found and found.length
								# donation sharing our ID has been found - use it instead
								base = found[0]
								action = "updating"
							else
								# create a new donation record and add it to the array
								base = _.extend donation,
									id: statusData.id
									amount: statusData.amount
									time: (new Date()).getTime()
									giftVisible: yes
								donations.push base
								action = "creating"
							base.status = statusData.status
							console.log "#{action} donation record #{base.id} of #{decodedData.treeId}"
							treeDb.saveDocument treeDoc, wrapError res, (saveRes) ->
								res.redirect "/#{treeDoc._id}/donated"
			else
				res.send "Some required data was missing from the request", 500
		else
			res.send "incorrectly formatted re-entry URL", 500
