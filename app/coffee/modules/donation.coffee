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

		fadePaneContents = ($pane) ->
			$pane.children().animate
				opacity: 0.5
			, 500

		setupSelectedGift = ($gift, $selected, $target, doneFn = ->) ->
			$gift.addClass 'selected'
			$target.addClass (newClass = $gift.data('gift'))
			$target.removeClass oldClass if oldClass = $target.data('gift')
			$target.data 'gift', newClass
			$selected.fadeIn('fast', doneFn) if not $selected.is(':visible')

		selectGift: (e) ->
			$gift = $(e.target)
			$selectedGift = @$('.selected-gift')
			$sketchTeaser = $('.sketch-teaser')
			@$el.addClass 'gift-chosen'
			fadePaneContents $('.left')
			showFn = =>
				setupSelectedGift $gift, $selectedGift, $selectedGift.find('li')

			if $sketchTeaser.is ':visible'
				$sketchTeaser.fadeOut 'fast', showFn
			else showFn()

	Donation
