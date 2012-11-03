module.exports = (config) ->
	everyauth = require 'everyauth'
	{Promise} = everyauth

	everyauth.twitter
		.consumerKey( config.twitter.consumerKey )
		.consumerSecret( config.twitter.consumerSecret )
		.findOrCreateUser (session, accessToken, accessTokenSecret, twitterUserData) ->
			console.log twitterUserData
		.redirectPath('/sketch')

	everyauth
