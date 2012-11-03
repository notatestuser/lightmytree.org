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

	findOrCreateByTwitter: (promise, userData, accessToken, accessTokenSecret) ->
		@users.view 'users/byTwitter', key: userData.id_str, (err, doc) =>
			if err
				throw err
			else if doc.length
				promise.fulfill doc
			else
				providerData =
					id: userData.id_str
					accessToken: accessToken
					accessTokenSecret: accessTokenSecret
				doc = createDocument 'twitter', providerData, userData.screen_name, userData.name,
					userData.profile_image_url, userData.location
				@users.save doc, (err, res) ->
					if err
						throw err
					else
						console.log "Twitter user created: #{userData.screen_name}"
						promise.fulfill doc

exports.UserDatabase = UserDatabase
