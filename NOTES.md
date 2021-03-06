LightMyTree
===========

Flow
----

```
[Home Page] -> [Tree Sketcher] -> [Tree Page] -> Back
[Tree Page] -> [Donate] -> [Tree Page] -> Back
[Tree Page] -> [Tree Sketcher] -> [Tree Page] -> Back
```

The Never Ending 'To Do'
------------------------

I'm leaving out the incredibly obvious stuff like TEST COVERAGE as this is merely a list of things required to get our first prototype online.

### High priority

* attempted in branch: CSS vendor prefixing (use cssFx and remove all vendor-specific prefixing?)
* require.js optimizer
* INTERNET EXPLORER TESTING - :before :after IE polyfill
* Gzipped requests & responses for static assets & API
* (done) Open Graph Protocol tags
* (done) Strip down size of header-bg.png
* (done) "Horrible content will be removed pronto"
* (done) Clear local storage on final share (to prevent edits and clean up)
* (done) Social network sharing buttons
* (done) Tree PNG generation and serving

### Medium priority

* Prevent unnecessarily repeated redraws
* Limit drawing submissions in UI & data layer
* Limit stroke submissions in UI & data layer
* Limit charity selections in data layer
* Enough(tm) pencil colours
* Mobile sketchpad responsiveness
* ERROR: sendDatabaseError()
	{ error: 'conflict', reason: 'Document update conflict.' }
	Trace: sendDatabaseError
	    at module.exports.sendDatabaseError (/Users/luke/Dropbox/Greenfield/lightmytree/app/routes/data.js:40:15)
	    at module.exports.createOrUpdateFn (/Users/luke/Dropbox/Greenfield/lightmytree/app/routes/data.js:89:21)
	    at BaseDatabase.saveDocument (/Users/luke/Dropbox/Greenfield/lightmytree/app/database.js:39:16)
* (done) Convert Bootstrap to use individual modules to reduce initial payload size (don't send over all of Bootstrap...)

### Low priority

* Artificial latency with the contrived fixtures
* Coffeescript server start fix
* Sandbox/prod routing configuration (sort of done, we still need to be able to switch in and out of fixture mode)
* Re-initialise sketchpad on resize (Chrome bug)
* Stop using API key in Backbone model URLs; instead use the URL mechanism already in place
* Glowing baubles

### ???
* SVG path optimisation/compression


Testing Strategy
----------------

I've envisioned three 'environment' modes:

* _dev_ uses "canned response" fixtures to emulate real back-end data calls (for rapid front-end dev.)
* _test_ will use a mocked server that appropriately deals with input data (sandboxes?)
* _production_ will be hooked up to real APIs and such


Data URL Schemes
----------------

These will have fixtures made up for them (as above):

```
Data interface action         | Feed
-----------------------------------------------------------------
log in                        | get user object (server-side),
                                 make available over http (or not)
post to /my_tree              | add tree object, get user object,
                                 add id to user object, save
/users/:user_id               | all trees by user id
                                 ({user} -> {trees},
                                  load strokes async)
/trees/:slug                  | search user collection for tree
                                 with given ID

Live feeds:
	/json/recent_charities
	/json/recent_trees
	/json/trees/<user_id> (all trees authored by user)
	/json/tree/id (first tree that matches given slug)

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
