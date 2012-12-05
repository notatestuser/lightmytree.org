define [
	"app"
	"lodash"
	"backbone"
	"modules/tree"
	"modules/modal"
	"bootstrap/bootstrap-tooltip"
],

(app, _, Backbone, Tree, Modal) ->

	Donation = app.module()

	class Donation.Model extends Backbone.Model
		defaults:
			charityId: -1
			treeId: -1
			name: ''
			message: ''
			gift: 'gift-1'
			giftPlacing: no
			giftDropX: 0
			giftDropY: 0
			giftVisible: no

		url: -> "/json/trees/#{@get 'treeId'}/donations"

		getCharity: ->
			@collection.lookupCharity @get('charityId') if @collection

	class Donation.Collection extends Backbone.Collection
		model: Donation.Model

		initialize: (models, options) ->
			@charities = options.charities if options.charities

		lookupCharity: (charityId) ->
			@charities.get charityId

	class Donation.Views.GiftPicker extends Backbone.View
		template: 'tree/view/donation_gifts'

		events:
			"click .selectable": "_beginSelectGift"
			"click .btn-donate-anyway": "_beginSelectGift"
			"click .btn-proceed": "_beginDonation"

		initialize: ->
			@model.on 'change:giftPlacing change:charityId', @_renderStateContent, @
			@collection.on 'reset fetched', @render, @

		afterRender: ->
			@collection.forEach (charityModel) ->
				@insertView '.nav-charities', new Donation.Partials.Charity
					model: charityModel
					donationModel: @model
				.render()
			, @
			@_renderStateContent()

		_fadePaneContents = ($pane) ->
			$pane.children().animate
				opacity: 0.5
			, 500

		_setupSelectedGift = (newClass, $gift, $selected, $targets, doneFn) ->
			$gift.addClass 'selected'
			$targets.addClass (newClass = $gift.data('gift'))
			$targets.removeClass oldClass if oldClass = $targets.data('gift')
			$targets.data 'gift', newClass
			$selected.fadeIn('fast', doneFn) if not $selected.is(':visible')

		_beginSelectGift: (e) ->
			$gift = $(e.target)
			$selectedGift = @$('.selected-gift')
			$selectedGiftEls = $selectedGift.find('.gifts *')
			# $selectedGiftEls = @$('.selected-gift .gifts .decoration').first
			$sketchTeaser = $('.sketch-teaser')
			newClass = $gift.data('gift')
			@$el.addClass 'gift-chosen'
			_fadePaneContents @$el.children(':not(.follow)')
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

		_beginDonation: ->
			@model.save
				name: @$('.input-name').val()
				message: @$('.input-message').val()

		_renderStateContent: =>
			$proceedBtn = @$('.btn-proceed')
			proceedBtnDisabled = yes
			if (not @model.get('giftPlacing') and @model.get('giftDropX') > 0) or @model.get('gift') is 'none'
				$heading = @$('.heading')
				if @model.get('charityId') is -1
					$heading.html 'Great! Now select your charity.'
				else
					$heading.html 'Click "Donate" to proceed!'
					proceedBtnDisabled = no
			$proceedBtn.prop 'disabled', proceedBtnDisabled

			# flash the .follow's background color
			$follow = @$('.follow')
				.removeClass('flash-fade')

			# this seems to be the easiest way to restart the animation! hmph...
			setTimeout (->
				$follow.addClass('flash-fade')
			), 50

	class Donation.Views.Gift extends Backbone.View
		className: 'decoration'

		initialize: ->
			@model.on 'change:gift change:giftPlacing', @render, @
			if charity = @model.getCharity()
				charity.on 'change:name', @render, @

		beforeRender: ->
			@$el.removeClass @giftClass if @giftClass
			@$el
				.addClass(@giftClass = @model.get('gift'))
				.css
					top: @model.get('giftDropY')
					left: @model.get('giftDropX')

			if not @model.get 'giftPlacing'
				@$el.removeClass 'placing'
				@_setupTooltip()
			else
				@$el.addClass 'placing'

			# emulate some gravity or something after rendering?

		setDrawOffset: (x, y) ->
			@$el.css
				top: y
				left: x

		getDropOffset: ->
			parentOffset = @$el.parent().offset()
			thisOffset = @$el.offset()
			x = Math.round((thisOffset.left - parentOffset.left) * 100) / 100
			y = Math.round((thisOffset.top - parentOffset.top) * 100) / 100
			{x: x, y: y}

		_setupTooltip: ->
			tooltipText = if name = @model.get('name') then name else ''
			charity = @model.getCharity()
			if charity and charityName = charity.get 'name'
				tooltipText += if not tooltipText.length then 'Donation ' else ' donated '
				tooltipText += 'to ' + charityName
			else
				tooltipText += 'donated'
			@$el.tooltip 'destroy'
			@$el.tooltip
				title: tooltipText
				placement: 'top'

	class Donation.Partials.Charity extends Backbone.View
		tagName: 'li'

		events:
			"click": "_handleClick"

		initialize: (options) ->
			if options.donationModel?
				@donationModel = options.donationModel
				@donationModel.on 'change:charityId', @render, @

		beforeRender: ->
			if not @$el.children().length
				content = @model.get('name')
				content += '<i class="icon-chevron-right"></i>'
				$('<a href="#">'+content+'</a>').appendTo @$el

		afterRender: ->
			if @donationModel? and parseInt(@donationModel.get('charityId')) is parseInt(@model.id)
				@$el.addClass 'active'
			else
				@$el.removeClass 'active'

		_handleClick: (ev) =>
			ev.preventDefault()
			@donationModel.set charityId: @model.id if @donationModel
			false


	class Donation.RedirectListener
		constructor: (donationModel) ->
			donationModel.on 'change:redirectUrl', @performRedirect, @

		performRedirect: (model, url) ->
			modal = new Modal.Views.DonateRedirect
				processorName: 'JustGiving'
				url: url
			modal.render() # showAfterRender is set, so the modal will show


	Donation
