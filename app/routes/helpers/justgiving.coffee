https   = require 'https'
{parse} = require 'url'
{_}     = require 'underscore'

class JustGiving
	@DirectDonatePath = '/donation/direct/charity'

	constructor: (@siteUrl, @apiUrl, @apiKey) ->

	getDonationUrl: (charityId, callbackUrl, ourData, thirdPartyReference, amount) ->
		url = @siteUrl + JustGiving.DirectDonatePath
		url += "/#{charityId}?frequency=single"
		url += "&amount=#{amount}" if amount?
		url += "&reference=" + encodeURIComponent(thirdPartyReference) if thirdPartyReference?
		url += "&exitUrl=" + encodeURIComponent(callbackUrl + "?id=JUSTGIVING-DONATION-ID&data=#{encodeURIComponent(ourData)}")
		url

	getDonationStatus: (donationId, callback) ->
		# http get the URL below
		url = @apiUrl + "/#{@apiKey}/v1/donation/#{donationId}"
		buf = ''

		opts =
			headers:
				'Accept': 'application/json'

		https.get _.extend(parse(url), opts), (res) ->
			console.log "getDonationStatus() for #{donationId} responded with #{res.statusCode}"

			res.on 'data', (data) ->
				buf += data

			res.on 'end', ->
				callback null, JSON.parse(buf)

		.on 'error', (e) ->
			callback e

module.exports = JustGiving
