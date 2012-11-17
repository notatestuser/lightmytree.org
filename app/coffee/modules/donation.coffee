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
			type: 'gift-1'
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

		setupSelectedGift = (newClass, $gift, $selected, $target, doneFn) ->
			$gift.addClass 'selected'
			$target.addClass (newClass = $gift.data('gift'))
			$target.removeClass oldClass if oldClass = $target.data('gift')
			$target.data 'gift', newClass
			$selected.fadeIn('fast', doneFn) if not $selected.is(':visible')

		selectGift: (e) ->
			$gift = $(e.target)
			$selectedGift = @$('.selected-gift')
			$sketchTeaser = $('.sketch-teaser')
			newClass = $gift.data('gift')
			@$el.addClass 'gift-chosen'
			fadePaneContents $('.left')
			showFn = =>
				setupSelectedGift newClass, $gift, $selectedGift, $selectedGift.find('li'), =>
					setTimeout =>
						console.log 'row-sketchpad offset is ' + $('.row-sketchpad').offset().top
						# TODO fix this - works in FF
						$('html').animate
							scrollTop: $('.row-holly.row-first').offset().top
					, 1000

			if $sketchTeaser.is ':visible'
				$sketchTeaser.fadeOut 'fast', showFn
			else showFn()

			# create the model
			donation = new Donation.Model
				type: newClass
			# fire event or add to Tree
			# re-render Tree view (which is probably why we'd favour an event)

	Donation
