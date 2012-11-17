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
			treeId: -1
			name: 'Anonymous'
			message: 'n/a'
			gift: 'gift-1'
			giftSelected: no
			giftDropX: 0
			giftDropY: 0
			giftVisible: no

		url: -> "/json/trees/#{@get 'treeId'}/donations"

	class Donation.Collection extends Backbone.Collection
		model: Donation.Model

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
						# TODO fix this - works in FF
						$('html').animate
							scrollTop: $('.row-holly.row-first').offset().top
					, 1000

			if $sketchTeaser.is ':visible'
				$sketchTeaser.fadeOut 'fast', showFn
			else showFn()

			# set the model's gift
			@model.set
				gift: newClass
				giftSelected: yes

			# fire event or add to Tree
			# re-render Tree view (which is probably why we'd favour an event)

	class Donation.Views.Gift extends Backbone.View
		className: 'decoration placing'

		initialize: ->
			@model.on 'change:gift', @render, @

		beforeRender: ->
			@$el.removeClass @giftClass if @giftClass
			@$el.addClass @giftClass = @model.get('gift')

		setDrawOffset: (x, y) ->
			@$el.css
				top: y
				left: x

		getDropOffset: ->
			parentOffset = @$el.parent().offset()
			thisOffset = @$el.offset()
			x:	thisOffset.left - parentOffset.left, y: thisOffset.top - parentOffset.top


	Donation
