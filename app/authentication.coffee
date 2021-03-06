module.exports = (config) ->
	everyauth = require 'everyauth'
	{UserDatabase} = require './database'

	# TODO should we make a new UserDatabase each time?
	userDb = new UserDatabase config

	everyauth.everymodule
		.userPkey('_id') # CouchDB primary key field
		.findUserById (userId, callback) ->
			db = new UserDatabase config
			db.findById userId, callback

	everyauth.twitter
		.consumerKey( config.twitter.consumerKey )
		.consumerSecret( config.twitter.consumerSecret )
		.findOrCreateUser (session, accessToken, accessTokenSecret, twitterUserData) ->
			promise = @Promise()
			try
				userDb.findOrCreateByTwitter promise, twitterUserData, accessToken, accessTokenSecret
			catch err
				console.error 'Error whilst finding or creating Twitter user', err
			promise
		.redirectPath('/my_trees')

	everyauth.facebook
		.scope('publish_actions')
		.fields('id,name,username,locale,picture')
		.appId( config.facebook.appId )
		.appSecret( config.facebook.appSecret )
		.handleAuthCallbackError (req, res) ->
			res.redirect '/'
		.findOrCreateUser (session, accessToken, accessTokExtra, fbUserMetadata) ->
			promise = @Promise()
			try
				userDb.findOrCreateByFacebook promise, fbUserMetadata, accessToken, accessTokExtra
			catch err
				console.error 'Error whilst finding or creating Facebook user', err
			promise
		.redirectPath('/my_trees')

	everyauth
