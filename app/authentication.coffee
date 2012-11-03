module.exports = (config) ->
	everyauth = require 'everyauth'
	{UserDatabase} = require './database'

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
		.redirectPath('/sketch')

	everyauth
