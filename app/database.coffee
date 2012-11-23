{Connection} = require 'cradle'
{_}          = require 'underscore'

class BaseDatabase
	constructor: (@config, @dbKey) ->
		connection = new Connection @config.couchdb.url, @config.couchdb.port,
			cache: true
		@db = connection.database @config.dbs[@dbKey]

	findById: (id, callback) ->
		@db.view "#{@dbKey}/byId", key: id, (err, res) ->
			return callback err, res[0].value if res and res.length
			callback err, null

	saveDocument: (doc, callback) ->
		@db.save doc, (err, res) ->
			console.trace 'saveDocument' if err
			callback err, res

class UserDatabase extends BaseDatabase
	@PrivateFields = [ 'location', 'twitter', 'facebook' ]

	constructor: (config) ->
		super config, 'users'

	createDocument = (provider, providerData, screenName, fullName, imageUrl, location) ->
		doc = {}
		[doc.screenName, doc.fullName, doc.imageUrl, doc.location, doc.trees] = [screenName, fullName, imageUrl, location, []]
		doc[provider] = if providerData then providerData else {}
		doc

	findOrCreateByTwitter: (promise, userData, accessToken, accessTokenSecret) ->
		@db.view 'users/byTwitter', key: userData.id_str, (err, doc) =>
			if err
				console.error err
				promise.fail err
			else if doc and doc.length
				promise.fulfill doc[0].value
			else
				providerData =
					id: userData.id_str
					accessToken: accessToken
					accessTokenSecret: accessTokenSecret
				newDoc = createDocument 'twitter', providerData, userData.screen_name, userData.name,
					userData.profile_image_url, userData.location
				@db.save newDoc, (err, res) ->
					if err
						console.error err
						throw err
					else
						console.log "Twitter user created: #{userData.screen_name}"
						newDoc._id = newDoc.id = res.id # defensive programming!
						promise.fulfill newDoc

	findOrCreateByFacebook: (promise, userData, accessToken, accessTokExtra) ->
		@db.view 'users/byFacebook', key: userData.id, (err, doc) =>
			if err
				console.error err
				promise.fail err
			else if doc and doc.length
				promise.fulfill doc[0].value
			else
				providerData =
					id: userData.id
					accessToken: accessToken
					accessTokenExtra: accessTokExtra
				newDoc = createDocument 'facebook', providerData, userData.username or userData.name, userData.name,
					userData.picture, userData.locale
				@db.save newDoc, (err, res) ->
					if err
						console.error err
						throw err
					else
						console.log "Facebook user created: #{userData.username}"
						newDoc._id = newDoc.id = res.id # defensive programming!
						promise.fulfill newDoc

class TreeDatabase extends BaseDatabase
	constructor: (config) ->
		super config, 'trees'

	checkIdTaken = (treeId, callback) ->
		@db.view "#{@dbKey}/checkId", key: treeId, (err, res) ->
			console.error err if err
			callback res and res.length, treeId

	# screenName, screenName-1, screenName-2, etc...
	makeSlugId = (user, callback) ->
		screenName = user.screenName.replace '-', '_'
		tries = 0
		idCheckCallbackFn = ((taken, triedId) ->
			console.log "tried username #{triedId}, is taken: #{taken}"
			if taken
				checkIdTaken.call @, "#{screenName}-#{++tries}", idCheckCallbackFn
			else
				callback triedId
		).bind @
		checkIdTaken.call @, screenName, idCheckCallbackFn

	createDocument = (userDoc, data, makeId, callback) ->
		if not data.strokes?.length? or not data.charityIds?.length?
			throw "`strokes` and `charityIds` must have some entries"
		# list of whitelisted fields to cherry-pick
		doc = _.pick data, 'strokes', 'charityIds', 'viewBoxWidth', 'viewBoxHeight', 'publishGraphAction'
		doc.user = id: userDoc._id
		if makeId
			makeSlugId.call @, userDoc, (slugId) ->
				doc._id = slugId
				callback doc
		else callback doc

	createOrUpdate: (userDoc, data, callback) ->
		args = if data.id? and data.id.length? then [data.id] else []
		try
			createDocument.call @, userDoc, data, !args.length, (doc) =>
				args.push doc
				args.push callback
				@db.save.apply @db, args
		catch err
			callback err, null

	findByUserId: (userId, callback) ->
		@db.view "#{@dbKey}/byUserId", key: userId, (err, res) ->
			return callback err, (doc.value for doc in res) if res
			callback err, null

exports.UserDatabase = UserDatabase
exports.TreeDatabase = TreeDatabase
