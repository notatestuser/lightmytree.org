https   = require 'https'
{parse} = require 'url'
{_}     = require 'underscore'

class JustGiving
	@DirectDonatePath   = '/donation/direct/charity'
	@GetDonationDetails = '/v1/donation/'
	@CharitySearch      = '/v1/charity/search'

	doApiCall = (fullUrl, apiKey, callback) ->
		buf = ''

		opts =
			headers:
				'Accept': 'application/json'
				'x-api-key': apiKey

		req = https.get _.extend(parse(fullUrl), opts), (res) ->
			console.log "JG: #{fullUrl} responded with #{res.statusCode}"
			# we're permitting 404s because they can be a very valid response...
			if res.statusCode isnt 200 and res.statusCode isnt 404
				callback? "status #{res.statusCode}"
				req.abort()

			res.on 'data', (data) ->
				buf += data

			res.on 'end', ->
				callback? null, JSON.parse(buf)

		.on 'error', (e) ->
			callback? e

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
		url = @apiUrl + JustGiving.GetDonationDetails + donationId
		doApiCall url, @apiKey, callback

	charitySearch: (query, pageSize = 4, page = 1, callback) ->
		url = @apiUrl + JustGiving.CharitySearch
		url += "?q=" + query
		url += "&pageSize=" + pageSize if pageSize
		url += "&page=" + page if page
		doApiCall url, @apiKey, callback


module.exports = JustGiving
