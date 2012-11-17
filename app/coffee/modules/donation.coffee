define [
	"app"
	"lodash"
	"backbone"
	"modules/tree"
],

(app, _, Backbone, Tree) ->

	Donation = app.module()

	class Donation.Model extends Backbone.Model
		defaults:
			charityId: -1
			type: 'gift'
			name: 'Anonymous'
			message: 'n/a'

	class Donation.Views.GiftPicker extends Backbone.View
		template: 'tree/view/donation_gifts'

		events:
			"click .selectable": "selectGift"

		selectGift: (e) ->
			$(e.target).addClass 'selected'
			@$el.addClass 'gift-chosen'

	Donation
