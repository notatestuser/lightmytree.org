{_}       = require 'underscore'
{inspect} = require 'util'
{TreeDatabase, UserDatabase} = require '../database'

module.exports = (app, config) ->

	console.log "Defining DATA routes"

	userDb = new UserDatabase config
	treeDb = new TreeDatabase config

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
	app.get /^\/json\/users\/([a-z0-9]+)?$/, withAuth (req, res, userId) ->
		id = req.params[0] or userId
		if id
			userDb.findById req.params[0] or userId, (err, doc) ->
				sendDatabaseError(err, res) if err
				res.json _.omit(doc, UserDatabase.PrivateFields) if doc
				res.send "Not found", 404 if not doc
		else
			res.send "Please authenticate or supply a user ID", 401

	# /json/trees/:id
	app.get /^\/json\/trees\/([a-zA-Z0-9_.]+)?$/, (req, res) ->
		if req.params[0]
			treeDb.findById req.params[0], (err, doc) ->
				sendDatabaseError(err, res) if err
				res.json(doc) if doc
				res.send "Not found", 404 if not doc
		else
			res.send "Not found", 404

