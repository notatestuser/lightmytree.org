define [
	"app"
	"lodash"
	"backbone"
	"modules/tree"
	"modules/modal"
],

(app, _, Backbone, Tree, Modal) ->

	Donation = app.module()

	class Donation.Model extends Backbone.Model
		defaults:
			charityId: -1
			treeId: -1
			name: 'Anonymous'
			message: 'n/a'
			gift: 'gift-1'
			giftPlacing: no
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
			"click .btn-proceed": "beginDonation"

		initialize: ->
			@model.on 'change:giftPlacing', @_changeGiftPlacing, @

		fadePaneContents = ($pane) ->
			$pane.children().animate
				opacity: 0.5
			, 500

		_setupSelectedGift = (newClass, $gift, $selected, $targets, doneFn) ->
			$gift.addClass 'selected'
			$targets.addClass (newClass = $gift.data('gift'))
			$targets.removeClass oldClass if oldClass = $targets.data('gift')
			$targets.data 'gift', newClass
			$selected.fadeIn('fast', doneFn) if not $selected.is(':visible')

		selectGift: (e) ->
			$gift = $(e.target)
			$selectedGift = @$('.selected-gift')
			$selectedGiftEls = $selectedGift.find('.gifts *')
			# $selectedGiftEls = @$('.selected-gift .gifts .decoration').first
			$sketchTeaser = $('.sketch-teaser')
			newClass = $gift.data('gift')
			@$el.addClass 'gift-chosen'
			fadePaneContents @$el.children(':not(.follow)')
			showFn = =>
				_setupSelectedGift newClass, $gift, $selectedGift, $selectedGiftEls, =>
					setTimeout =>
						# TODO fix this - works in FF
						$('html').animate
							scrollTop: $('.row-holly.row-first').offset().top
					, 1000

			# if $sketchTeaser.is ':visible'
			# 	$sketchTeaser.fadeOut 'fast', showFn
			# else showFn()
			showFn()

			# set the model's gift
			@model.set
				gift: newClass
				giftPlacing: yes

			@$('.follow')
				.fadeIn('slow')
				.css
					position: 'fixed'
					bottom: 0
					left: 0

		beginDonation: ->
			@model.save()

		_changeGiftPlacing: (model, value) ->
			@$('.heading').html 'Great! Now select your charity.' if not value

	class Donation.Views.Gift extends Backbone.View
		className: 'decoration placing'

		initialize: ->
			@model.on 'change:gift', @render, @

		beforeRender: ->
			@$el.removeClass @giftClass if @giftClass
			@$el
				.addClass(@giftClass = @model.get('gift'))
				.css
					top: @model.get('giftDropY')
					left: @model.get('giftDropX')
			# emulate some gravity or something after rendering?

		setDrawOffset: (x, y) ->
			@$el.css
				top: y
				left: x

		getDropOffset: ->
			parentOffset = @$el.parent().offset()
			thisOffset = @$el.offset()
			x:	thisOffset.left - parentOffset.left, y: thisOffset.top - parentOffset.top

	class Donation.RedirectListener
		constructor: (donationModel) ->
			donationModel.on 'change:redirectUrl', @performRedirect, @

		performRedirect: (model, url) ->
			modal = new Modal.Views.DonateRedirect
				processorName: 'JustGiving'
				url: url
			modal.render() # showAfterRender is set, so the modal will show


	Donation
