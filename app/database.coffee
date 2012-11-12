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
						throw err
					else
						console.log "Twitter user created: #{userData.screen_name}"
						console.log res
						newDoc._id = newDoc.id = res.id # defensive programming!
						promise.fulfill newDoc

class TreeDatabase extends BaseDatabase
	constructor: (config) ->
		super config, 'trees'

	createDocument = (userId, data) ->
		if not data.strokes?.length? or not data.charityIds?.length?
			throw "`strokes` and `charityIds` must have some entries"
		doc = _.pick data, 'strokes', 'charityIds', 'viewBoxWidth', 'viewBoxHeight'
		doc.user = id: userId
		doc

	createOrUpdate: (userId, data, callback) ->
		args = if data.id? and data.id.length? then [data.id] else []
		try
			args.push createDocument(userId, data)
		catch err
			callback err, null
		args.push callback
		@db.save.apply @db, args

	findByUserId: (userId, callback) ->
		@db.view "#{@dbKey}/byUserId", key: userId, (err, res) ->
			return callback err, (doc.value for doc in res) if res
			callback err, null

exports.UserDatabase = UserDatabase
exports.TreeDatabase = TreeDatabase
