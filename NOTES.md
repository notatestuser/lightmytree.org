LightMyTree
===========

Flow
----

```
[Home Page] -> [Tree Sketcher] -> [Tree Page] -> Back
[Tree Page] -> [Donate] -> [Tree Page] -> Back
[Tree Page] -> [Tree Sketcher] -> [Tree Page] -> Back
```

Testing Strategy
----------------

I've envisioned three 'environment' modes:

* _dev_ uses "canned response" fixtures to emulate real back-end data calls (for rapid front-end dev.)
* _test_ will use a mocked server that appropriately deals with input data
* _production_ will be hooked up to real APIs and such


Data URL Schemes
----------------

These will have fixtures made up for them (as above):

```
Live feeds:
	/json/recent_charities

Mocked APIs (fixture mode):
	/api/donation/direct/charity/{charityId}/donate
		?amount=<amount>&frequency=single
			&exitUrl=http://our.app/?donationId=JUSTGIVING-DONATION-ID&id=<our_id>
	/api/<api_key>/v1/donation/<donation_id>

** to add: REST stuff for trees **
** to add: add social network/auth stuff **
```

Using the JustGiving API
------------------------

The application's API key is: e90e23e0

There are three environments

* https://api-sandbox.justgiving.com – paired with http://v3-sandbox.justgiving.com
* https://api-staging.justgiving.com – paired with http://v3-staging.justgiving.com
* https://api.justgiving.com – paired with http://www.justgiving.com

### Links

* [API documentation](https://api.justgiving.com/docs)
* [Usage documentation](https://api.justgiving.com/docs/usage)

### Content Types

We support Json, XML and experimentally JsonP (with a callback= query string parameter). You must ensure you set your HTTP headers correctly (Content-type and Accept) while making requests to ensure that we understand your requests and can respond accordingly.
