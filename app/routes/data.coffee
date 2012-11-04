{inspect}      = require 'util'
{TreeDatabase} = require '../database'

module.exports = (app, config) ->

	console.log "Defining DATA routes"

	treeDb = new TreeDatabase config

	ensureAuth = (callback) ->
		(req, res) ->
			if not req.user? or not req.user._id?
				res.send "Please authenticate", 401
			else
				callback req, res, req.user._id

	# /json/my_tree
	myTreeFn = ensureAuth (req, res, userId) ->
		data = req.body

		createOrUpdateFn = ->
			treeDb.createOrUpdate userId, data, (err, dbRes) ->
				if err
					console.error "ERROR: in treeDb.createOrUpdate"
					console.error inspect(err)
					res.send "Database error", 500
				else
					res.json
						id: dbRes.id

		# if an ID is being provided, ensure the target tree belongs to this user
		if data.id? and data.id.length?
			treeDb.findById data.id, (err, doc) ->
				if doc and doc.user.id isnt req.user._id
					console.error "ERROR: attempt to sabotage another user's tree"
					console.error "(user: #{req.user._id}, target ID: #{data.id})"
					res.send "Unauthorised", 401
				else
					if not doc
						console.error "ERROR: tree `#{data.id}` doesn't exist but referenced by `#{req.user._id}`; removing ID"
						delete data.id
					createOrUpdateFn()
		else
			createOrUpdateFn()

	app.post "/json/my_tree", myTreeFn
	app.put "/json/my_tree", myTreeFn
