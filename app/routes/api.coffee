{_} = require 'underscore'

# needed because eval() in Chrome requires that anonymous functions are surrounded with parenthesis
wrap = (fnString) ->
	"(" + fnString + ")"

urls =
	recent_charities: wrap (() ->
		"/json/recent_charities"
	).toString()

	typeahead_charities: wrap (() ->
		"/json/typeahead_charities"
	).toString()

	justgiving_charity: wrap (() ->
		app.env.justgiving.apiUrl + '/' +
		app.env.justgiving.apiKey +
		"/v1/charity"
	).toString()

	justgiving_charity_search: wrap ((query, pageSize = 8, page = 1) ->
		app.env.justgiving.apiUrl + '/' +
		app.env.justgiving.apiKey +
		"/v1/charity/search" +
		"?q=" + query +
		"&pageSize=" + pageSize +
		"&page=" + page
	).toString()

	# charity_donate: wrap ((charityId, amount, ourId) ->
	# 	JustGiving
	# 	+ "/donation/direct/charity/#{charityId}/donate"
	# 	+ "?amount=#{amount}"
	# 	+ "&frequency=single"
	# 	+ "&exitUrl="
	# 	+ encodeURI("http://our.app/callbacks/jg-donate?donationId=JUSTGIVING-DONATION-ID&id=#{ourId}")
	# ).toString()

	# donation_status: wrap ((donationId, appKey = JustGivingKey) ->
	# 	JustGiving
	# 	+ "/api/#{appKey}/v1/donation/#{donationId}"
	# ).toString()

module.exports = (app, config) ->
	console.log "Defining API routes"

	# /json/client_init
	app.get "/json/client_init", (req, res) ->
		res.json
			authed: req.user?
			env:
				justgiving: _.pick config.justgiving, 'apiKey', 'apiUrl'
			urls: urls

# # real response
