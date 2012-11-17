class JustGiving
	@DirectDonatePath = '/donation/direct/charity'

	constructor: (@siteUrl, @apiUrl, @apiKey) ->

	getDonationUrl: (charityId, callbackUrl, ourReference, amount) ->
		url = @siteUrl + JustGiving.DirectDonatePath
		url += "/#{charityId}/donate?frequency=single"
		url += "&amount=#{amount}" if amount
		url += "&exitUrl=" + encodeURIComponent(callbackUrl + "?donationId=JUSTGIVING-DONATION-ID&id=#{ourReference}")
		url

	getDonationStatus: (donationId) ->
		# http get the URL below
		url = @apiUrl + "/api/#{@apiKey}/v1/donation/#{donationId}"

module.exports = JustGiving
