module.exports = (app) ->

	console.log "Defining FIXTURE routes"

	# /json/client_init
	app.get "/json/client_init", (req, res) ->
		res.json urls:
			recent_charities: (()->
				"/json/recent_charities"
			).toString()

			charity_donate: ((charityId, amount, ourId) ->
				"/api"
				+ "/donation/direct/charity/#{charityId}/donate"
				+ "?amount=#{amount}"
				+ "&frequency=single"
				+ "&exitUrl="
				+ encodeURI("http://localhost:3000/callbacks/jg-donate?donationId=JUSTGIVING-DONATION-ID&id=#{ourId}")
			).toString()

			donation_status: ((apiKey, donationId) ->
				"/api/#{apiKey}/v1/donation/#{donationId}"
			).toString()

	# /json/recent_charities
	app.get "/json/recent_charities", (req, res) ->
		res.json "fill me out": "yes"

	# /api/donation/direct/charity/{charityId}/donate
	# 	?amount=<amount>&frequency=single
	# 		&exitUrl=http://our.app/?donationId=JUSTGIVING-DONATION-ID&id=<our_id>
	app.get "/api/donation/direct/charity/:charityId/donate", (req, res) ->
		res.redirect 301, req.query.exitUrl

	# /api/<api_key>/v1/donation/<donation_id>
	app.get "/api/:apiKey/v1/donation/:donationId", (req, res) ->
		res.json
			amount: "10.0000"
			donationDate: "/Date(1219998642000+0100)/"
			donationRef: "10895972"
			donorDisplayName: "Amanda Hey"
			estimatedTaxReclaim: 2.8205
			id: parseInt(req.params.donationId)
			message: "Good Luck Mark"
			source: "SponsorshipDonations"
			status: "Accepted"
