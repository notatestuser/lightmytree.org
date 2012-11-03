{Connection} = require 'cradle'

class BaseDatabase
	constructor: (@config) ->
		@connection = new Connection @config.couchdb.url, @config.couchdb.port,
			cache: true

class UserDatabase extends BaseDatabase
	constructor: (config) ->
		super config
		@users = @connection.database @config.dbs.usersDB

	createDocument = (provider, providerData, screenName, fullName, imageUrl, location) ->
		doc = {}
		[doc.screenName, doc.fullName, doc.imageUrl, doc.location] = [screenName, fullName, imageUrl, location]
		doc[provider] = if providerData then providerData else {}
		doc

	findById: (userId, callback) ->
		@users.view 'users/byId', key: userId, (err, res) ->
			return callback err, res[0].value if res and res.length
			callback err, null

	findOrCreateByTwitter: (promise, userData, accessToken, accessTokenSecret) ->
		@users.view 'users/byTwitter', key: userData.id_str, (err, doc) =>
			if err
				throw err
			else if doc and doc.length
				promise.fulfill doc[0].value
			else
				providerData =
					id: userData.id_str
					accessToken: accessToken
					accessTokenSecret: accessTokenSecret
				newDoc = createDocument 'twitter', providerData, userData.screen_name, userData.name,
					userData.profile_image_url, userData.location
				@users.save newDoc, (err, res) ->
					if err
						throw err
					else
						console.log "Twitter user created: #{userData.screen_name}"
						console.log res
						newDoc._id = newDoc.id = res.id # defensive programming!
						promise.fulfill newDoc

exports.UserDatabase = UserDatabase
