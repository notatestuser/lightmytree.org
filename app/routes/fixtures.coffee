module.exports = (app) ->

	console.log "Defining FIXTURE routes"

	# /json/client_init
	app.get "/json/client_init", (req, res) ->
		res.json
			authed: req.user?
			urls:
				recent_charities: wrap (()->
					"/json/recent_charities"
				).toString()

				charity_donate: wrap ((charityId, amount, ourId) ->
					"/api"
					+ "/donation/direct/charity/#{charityId}/donate"
					+ "?amount=#{amount}"
					+ "&frequency=single"
					+ "&exitUrl="
					+ encodeURI("http://localhost:3000/callbacks/jg-donate?donationId=JUSTGIVING-DONATION-ID&id=#{ourId}")
				).toString()

				donation_status: wrap ((apiKey, donationId) ->
					"/api/#{apiKey}/v1/donation/#{donationId}"
				).toString()

	# /json/recent_charities
	app.get "/json/recent_charities", (req, res) ->
		res.json [
			"charityId": "188496"
			"description": "Care for Cancer is a charity based in Omagh that provides information, advice and practical support to individuals and families who have been touched by cancer. "
			"logoFileName": "\/Utils\/imaging.ashx?width=120&square=120&imageType=charitybrandinglogo&img=e2d13251-f899-49c8-9843-be601e5332a3.jpg"
			"name": "Care for Cancer"
			"registrationNumber": "n\/a"
		,
			"charityId": "77144"
			"description": "Hayward House is a Palliative Cancer Care Unit, a &quot;hospice within a hospital&quot;.  It is dedicated to relieving the suffering of progressive cancer which can be physical, emotional, social or spiritual, and involves both the patients and the family.  Patients with motor neurone disease and their families also receive support from the Unit."
			"logoFileName": "\/Utils\/imaging.ashx?width=120&square=120&imageType=charitybrandinglogo&img=spacer.gif"
			"name": "Hayward House Cancer Care Trust"
			"registrationNumber": "1014356"
		,
			"charityId": "186685"
			"description": "Dimbleby Cancer Care provides practical and psychological support to cancer patients, their families and carers - mainly through its centres at Guy's and St Thomas Hospitals in London.  It is also a leading funder of national research into the care and support needs of those affected by cancer."
			"logoFileName": "\/Utils\/imaging.ashx?width=120&square=120&imageType=charitybrandinglogo&img=22767795-637a-4152-a545-d001d952b8a7.JPG"
			"name": "Dimbleby Cancer Care"
			"registrationNumber": "247558"
		,
			"charityId": "185470"
			"description": "Sunflowers provides a unique support service to individuals and families affected by a cancer diagnosis in the Merseyside region.Our aim is to see every patient with a cancer diagnosis have access to our service. \u000a\u000a"
			"logoFileName": "\/Utils\/imaging.ashx?width=120&square=120&imageType=charitybrandinglogo&img=d7e248bb-12b9-4efc-a201-ec89c8c756ff.jpg"
			"name": "Liverpool Cancer Care Group"
			"registrationNumber": "516462"
		# ,
		# 	"charityId": "185040"
		# 	"description": "Bradford Cancer Support is a local independent charity supporting those people touched by cancer in the Bradford and Airedale area.  The aim is to help and support patients, carers, families and the bereaved by offering practical, social and emotional support."
		# 	"logoFileName": "\/Utils\/imaging.ashx?width=120&square=120&imageType=charitybrandinglogo&img=895931f9-d2d3-4f9a-978f-5ca58e2bf7ae.GIF"
		# 	"name": "Bradford Cancer Support"
		# 	"registrationNumber": "519429"
		# ,
		# 	"charityId": "185470"
		# 	"description": "Sunflowers provides a unique support service to individuals and families affected by a cancer diagnosis in the Merseyside region.Our aim is to see every patient with a cancer diagnosis have access to our service. \u000a\u000a"
		# 	"logoFileName": "\/Utils\/imaging.ashx?width=120&square=120&imageType=charitybrandinglogo&img=d7e248bb-12b9-4efc-a201-ec89c8c756ff.jpg"
		# 	"name": "Liverpool Cancer Care Group"
		# 	"registrationNumber": "516462"
		]

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

	# needed because eval() in Chrome requires that anonymous functions are surrounded with parenthesis
	wrap = (fnString) ->
		"(" + fnString + ")"
