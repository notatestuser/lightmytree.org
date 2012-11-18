class JustGiving
	@DirectDonatePath = '/donation/direct/charity'

	constructor: (@siteUrl, @apiUrl, @apiKey) ->

	getDonationUrl: (charityId, callbackUrl, ourData, thirdPartyReference, amount) ->
		url = @siteUrl + JustGiving.DirectDonatePath
		url += "/#{charityId}?frequency=single"
		url += "&amount=#{amount}" if amount?
		url += "&reference=" + encodeURIComponent(thirdPartyReference) if thirdPartyReference?
		url += "&exitUrl=" + encodeURIComponent(callbackUrl + "?id=JUSTGIVING-DONATION-ID&data=#{ourData}")
		url

	getDonationStatus: (donationId) ->
		# http get the URL below
		url = @apiUrl + "/api/#{@apiKey}/v1/donation/#{donationId}"

module.exports = JustGiving
