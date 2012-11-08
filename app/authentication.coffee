module.exports = (config) ->
	everyauth = require 'everyauth'
	{UserDatabase} = require './database'

	# TODO should we make a new UserDatabase each time?

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
				db = new UserDatabase config
				db.findOrCreateByTwitter promise, twitterUserData, accessToken, accessTokenSecret
			catch err
				console.error 'Error whilst finding or creating Twitter user', err
			promise
		.redirectPath('/my_trees')

	everyauth
