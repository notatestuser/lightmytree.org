module.exports =

	sessionSecret: 'devmode'

	couchdb:
		url: 'http://admin:admin@dev.lightmytree.org'
		port: 5984

	dbs:
		users: 'lmt_users'
		trees: 'lmt_trees'

	justgiving:
		apiKey: 'e90e23e0'
		apiUrl: 'https://api-sandbox.justgiving.com'
		siteUrl: 'https://v3-sandbox.justgiving.com'
		callbackUrl: 'http://dev.lightmytree.org:3000/callback/jg'

	twitter:
		# Light My Tree Labs
		consumerKey: 'Ev4MopNlRrygyAYDCEkFUg'
		consumerSecret: '5DPw6SeeIChXriFOf0AT38O5pJWi0vfg8NChQvWY'

	facebook:
		# LightMyTree Labs
		appId: '532521580109742'
		appSecret: 'e7cd640d2c338ff60f6e594bd6636fa4'
