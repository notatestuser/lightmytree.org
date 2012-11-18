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
				callback doc

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
			donation = _.pick decodedData, 'charityId', 'name', 'message', 'gift', 'giftDropX', 'giftDropY'
			if decodedData.treeId?
				charityService.getDonationStatus req.query.id, wrapError res, (statusData) ->
					console.log 'in callback'
					console.log arguments
				# treeDb.findById decodedData.treeId, wrapError res, (treeDoc) ->
				# 	if not treeDoc
				# 		res.send "Not found", 404
				# 	else
				# 		donation = _.pick data, 'charityId', 'name', 'message', 'gift', 'giftDropX', 'giftDropY'
				# 		donation.treeId = treeId
				# 		if Object.keys(donation).length isnt 6
				# 			res.send "More data required", 500
				# 		else
							# donation.id = (new Date()).getTime()
							# donations = treeDoc.donations ?= []
							# donations.push donation
							# treeDb.saveDocument treeDoc, wrapError res, (saveRes) ->
							# 	ourRef = "#{treeId}_#{donation.id}" # <treeId>_<time>
			else
				res.send "treeId required", 500

		else
			res.send "incorrectly formatted re-entry URL", 500
