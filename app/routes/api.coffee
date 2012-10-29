module.exports = (app) ->
	console.log "Defining API routes"

	JustGiving    = "https://api-sandbox.justgiving.com"
	JustGivingKey = "e90e23e0";

	# /json/client_init
	app.get "/json/client_init", (req, res) ->
		res.json urls:
			recent_charities: (() ->
				"/json/recent_charities"
			).toString()

			charity_donate: ((charityId, amount, ourId) ->
				JustGiving
				+ "/donation/direct/charity/#{charityId}/donate"
				+ "?amount=#{amount}"
				+ "&frequency=single"
				+ "&exitUrl="
				+ encodeURI("http://our.app/callbacks/jg-donate?donationId=JUSTGIVING-DONATION-ID&id=#{ourId}")
			).toString()

			donation_status: ((donationId, appKey = JustGivingKey) ->
				JustGiving
				+ "/api/#{appKey}/v1/donation/#{donationId}"
			).toString()



	# /json/recent_charities
	app.get "/json/recent_charities", (req, res) ->


# # real response
