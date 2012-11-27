define [
	"app"
	"lodash"
	"backbone"
	"raphael"
	"modules/charity"
	"modules/donation"
	"modules/modal"
	# "bootstrap/bootstrap-dropdown"
	"bootstrap/bootstrap-popover"
	# "bootstrap/bootstrap-button"

	"plugins/raphael.sketchpad"
	"plugins/jquery.sharrre-1.3.4.min"
],

(app, _, Backbone, Raphael, Charity, Donation, Modal) ->

	Tree = app.module()

	class Tree.Model extends Backbone.Model
		@LocalStorageKey = "Tree.Model"

		defaults:
			user: null
			charityIds: []
			donationData: []
			strokes: []
			viewBoxWidth: 430
			viewBoxHeight: 470
			templateId: ''
			publishGraphAction: no

		initialize: ->
			@charities = new Charity.Collection()
			@donations = new Donation.Collection null,
				charities: @charities

		fetch: (options = {}) ->
			oldCallback = options.success
			options.success = (model, response, options) =>
				@loadCharities()
				@loadDonations()
				oldCallback? model, response, options
			super options

		loadCharities: ->
			ids = @get 'charityIds'
			# @charities = new Charity.Collection ids
			@charities.reset (charityId: id for id in ids)

		loadDonations: ->
			@donations.reset @get('donationData')

		triggerGraphPublish: ->
			# there's no point doing this if we haven't been asked to publish an action
			if @get('publishGraphAction') and @id
				$.get "/#{@id}"

	class Tree.MyModel extends Tree.Model
		@MaxCharities: 4

		url: -> "/json/my_tree"

		initialize: ->
			@remotePersist = false
			super()
			@on 'change:strokes change:charityIds', (model) ->
				model.save()

		isNew: ->
			@get('strokes').length and super()

		sync: (method, model, options, first = true) ->
			defaultSyncFn = ->
				Backbone.sync method, model, options

			# intercept sync() attempt with localStorage persistence
			switch method
				when "create", "update"
					res = $.jStorage.set Tree.Model.LocalStorageKey, @toJSON()
					if @remotePersist
						$.jStorage.deleteKey Tree.Model.LocalStorageKey
						return defaultSyncFn()
					else
						options.success model, res, options
				when "read"
					try
						model.set $.jStorage.get(Tree.Model.LocalStorageKey, {})
					catch ex
					if app.authed
						defaultSyncFn()
					else
						options.success model, true, options
				when "delete"
					$.jStorage.deleteKey Tree.Model.LocalStorageKey

		validate: (attrs = @attributes) ->
			if not attrs.strokes or attrs.strokes.length < 1
				return "You must attempt to draw something!"
			# else if not attrs.charityIds or attrs.charityIds.length < 1
			# 	"You must select at least one charity!"

		addCharity: (model) ->
			if @get('charityIds').length < MyModel.MaxCharities
				@set 'charityIds', ids = _.union(@get('charityIds'), [model.id])
				@charities.push model
				# set the remaining count on the model
				model.set
					selected: yes
					remainingSelections: (MyModel.MaxCharities - ids.length)
			else no

		removeCharity: (model) ->
			@set 'charityIds', ids = _.without(@get('charityIds'), model.id)
			@charities.remove model
			model.set
				selected: no
				remainingSelections: (MyModel.MaxCharities - ids.length)

		setInitialCharityState: (model) ->
			selected = no
			if @get('charityIds').indexOf(model.id) isnt -1
				selected = yes
			model.set
				selected: selected
			, silent: yes

	class Tree.Collection extends Backbone.Collection
		url: "/json/trees"
		cache: yes

		# initialize: (models, options) ->
		# 	@userId = options.userId if options and options.userId?
		# 	@url += @userId if @userId
		# 	super models, options
		# 	@fetch()

		parse: (docs) ->
			_.extend(doc, id: doc._id) for doc in docs
			# example handling of an error response from the server
			#if obj.data.message isnt 'Error' then obj.data else @models

		comparator: (tree) ->
			-new Date(tree.get 'updated_at')

	class Tree.TemplateCollection extends Tree.Collection
		url: "/json/tree_templates"

	class Tree.Views.Save extends Backbone.View
		template: "tree/save"

		events:
			"click .btn-save": "save"

		initialize: ->
			@model.on 'change:strokes change:charityIds', @render, @

		serialize: ->
			charityCount: @model.get('charityIds').length
			maxCharities: Tree.MyModel.MaxCharities

		afterRender: ->
			@_setButtonDisabledState()

		save: ->
			if not @model.validate @model.attributes
				# rather than save() or show a modal, we just go straight to my_trees here
				app.router.go 'my_trees'

		_setButtonDisabledState: ->
			if @model.validate() or not @model.get('charityIds').length
				disabled = yes
			else
				disabled = no
			@$('.btn-save').prop 'disabled', disabled

	class Tree.Views.Share extends Backbone.View
		template: "tree/share"
		className: "tree-share-view well"

		events:
			"click .btn-group-facebook": "_showFacebookPublishDropdown"
			"click .btn-facebook-publish": "_authFacebookPublish"
			"click .btn-facebook-nopublish": "_authFacebookNoPublish"

		serialize: ->
			@model.toJSON()

		beforeRender: ->
			if app.authed
				view = new Tree.Partials.ShareLoggedIn
					model: @model
				@model.remotePersist = yes
				@model.save().done => @model.triggerGraphPublish()
			else
				view = new Tree.Partials.ShareNotLoggedIn
					model: @model
			@setView(".comment_section", view).render()

		_showFacebookPublishDropdown: ->
			@$('.btn-group-facebook .dropdown-menu').show()

		_authFacebookPublish: ->
			@_saveAndAuthFacebook yes

		_authFacebookNoPublish: ->
			@_saveAndAuthFacebook no

		_saveAndAuthFacebook: (publish = no) ->
			@model.save(publishGraphAction: publish)
			# usually we'd have to wait on the XHR to complete here, but as we're saving to localstorage we know it's done
			app.authRedirect 'facebook'

	class Tree.Partials.ShareLoggedIn extends Backbone.View
		template: "tree/share/logged_in"

		_showSuccessMessage = ->
			@$('.alert-saving').addClass 'hide'
			@$('.alert-success')
				.removeClass('hide')
				.addClass('in')

		initialize: ->
			@model.on 'sync', =>
				_showSuccessMessage.call @
				@insertView new Tree.Views.ShareWidgets
					model: @model
					showPublishGraphActionNotice: yes
				.render()

	class Tree.Partials.ShareNotLoggedIn extends Tree.Views.Save # inherit save event/handling
		template: "tree/share/not_logged_in"
		className: "tree-share-notloggedin-partial"

		afterRender: ->
			@$('.alert-not-logged-in').addClass 'in'

	class Tree.Views.Intro extends Backbone.View
		template: "tree/view/intro"

		initialize: ->
			# yes, we're chaining renders because the prior one supposedly hasn't finished
			@model.on 'change', => @render => @render()
			@collection.on 'reset', @render, @

		serialize: -> @model.toJSON()

		beforeRender: ->
			# this is here because we're not using an indepdendent view to represent the stuff in the collection - oh well
			if not @fetchingCharities
				encountered = finished = 0
				@collection.forEach (charityModel) ->
					@fetchingCharities = yes
					encountered++
					charityModel.fetch
						success: (model) =>
							if ++finished >= encountered
								# for the Donation.Views.GiftPicker to catch
								@collection.trigger 'fetched'
							@insertView '.charities', new Charity.Views.MiniItem
								model: charityModel
							.render()
				, @

	class Tree.Views.Solo extends Backbone.View
		# template: "tree/view"
		className: "tree-view"

		events:
			"click .gifts": "handleClick"
			# "touchstart .gifts": "handleClick"
			"mousemove .gifts": "handleMouseover"

		initialize: (options = {}) ->
			@model.on 'change', @render, @
			@model.donations.on 'reset', @render, @
			if options.myDonationModel
				@myDonationModel = options.myDonationModel
				@myDonationModel.on 'change:giftPlacing', @showDropLocation, @

		beforeRender: ->
			@$('.gifts').remove()
			$('<div class="gifts"></div>').appendTo @$el
			@model.donations.forEach (donationModel) ->
				if donationModel.get 'giftVisible'
					@insertView '.gifts', new Donation.Views.Gift
						model: donationModel
					.render()
			, @

		afterRender: ->
			self = @
			$container = @$el # this should be empty due to actions taken by beforeRender()
			if @paper?
				@paper.clear()
				@paper.setViewBox 0, 0,
					self.model.get('viewBoxWidth'), self.model.get('viewBoxHeight'), true
				@paper.add self.model.get('strokes')
			else
				@paper = new Raphael $container[0], $container.width(), $container.height()
				@paper.setViewBox 0, 0, @model.get('viewBoxWidth'), @model.get('viewBoxHeight'), true
				@paper.add @model.get('strokes')

		handleClick: =>
			if @myDonationModel.get 'giftPlacing'
				# add the donation model and re-render this view
				dropOffset = @myDonationView.getDropOffset()
				@myDonationModel.set
					giftDropX: dropOffset.x
					giftDropY: dropOffset.y
					giftPlacing: no
				@model.donations.add @myDonationModel
				@render()
				@$el.removeClass 'placing'

		handleMouseover: (ev) =>
			if @myDonationModel and @myDonationModel.get 'giftPlacing'
				@$el.addClass 'placing' if not @$el.hasClass 'placing'

				offset = $(ev.target).offset()
				offsetX = ev.clientX - offset.left
				offsetY = ev.pageY - offset.top

				#  positional difference checking
				# if @mouseOffsetX? and @mouseOffsetY?
				# 	diffX = Math.abs(offsetX - @mouseOffsetX)
				# 	diffY = Math.abs(offsetY - @mouseOffsetY)
				# 	return if diffX > 150 or diffY > 150

				# prevents a strange bug where the offset will suddenly become very low or negative
				if offsetX > 40 or offsetY > 40
					@myDonationView.setDrawOffset offsetX, offsetY

				[ @mouseOffsetX, @mouseOffsetY ] = [ offsetX, offsetY ]

		# this method will be called when the Donation's gift has been selected
		showDropLocation: ->
			@myDonationView = new Donation.Views.Gift
				model: @myDonationModel
			@insertView('.gifts', @myDonationView).render()

	class Tree.Views.List extends Backbone.View
		tagName: "ul"
		className: "tree-list-view row-fluid"

		events:
			"click .thumbnail": "_handleClickItem"

		initialize: (options = {}) ->
			@itemView = options.itemView or Tree.Views.Item
			@sketchModel = options.sketchModel if options.sketchModel?

		beforeRender: ->
			@collection.on 'reset', => @render()

			# TODO: dynamically create rows to prevent padding issues?
			if @collection and @collection.length
				@collection.forEach (treeModel) ->
					treeModel.fetch
						success: (model) =>
							@insertView new @itemView
								model: treeModel
							.render()
				, @
			else
				# TODO: fix this - it's rendering when it's not supposed to, messing up the layout
				# @insertView(new Tree.Partials.NothingToShow()).render()

		_handleClickItem: (ev) ->
			# only do something if we have a sketchModel (which means we're dealing with a list of possible templates)
			if @sketchModel?
				# get the selected tree's ID
				treeId = $(ev.target).closest('.thumbnail').data('id')
				@sketchModel.set 'templateTreeModel', @collection.get(treeId)

				# scroll to the row-sketchpad
				$('body').animate
					scrollTop: $('.row-sketchpad').offset().top
				, 500

	class Tree.Partials.NothingToShow extends Backbone.View
		tagName: "h4"

		beforeRender: ->
			@$el.html "There's nothing here. <a href='#sketch'>Draw something</a>"

	class Tree.Views.MiniItem extends Backbone.View
		# template: "tree/mini_list_item"
		tagName: "li"
		className: "micro-tree-view span3 thumbnail"

		beforeRender: ->
			@$el.data 'id', @model.id if @model?

		afterRender: ->
			# $container = @$('.canvas')
			$container = @$el
			@paper = new Raphael $container[0], $container.width(), $container.height()
			@paper.setViewBox 0, 0,
				@model.get('viewBoxWidth') or 0, @model.get('viewBoxHeight') or 0, true
			@paper.add @model.get('strokes')

	class Tree.Views.Item extends Backbone.View
		template: "tree/list_item"
		tagName: "li"
		className: "mini-tree-view span4 thumbnail"

		events:
			"click .canvas": "_goToTreePage"

		initialize: (options = {}) ->
			@hideShareWidgets = options.hideShareWidgets or no
			@model.on 'change:id', @render, @

		serialize: -> id: @model.id

		beforeRender: ->
			if not @hideShareWidgets
				@insertView new Tree.Views.ShareWidgets
					model: @model
				.render()

		afterRender: ->
			@$('.buttons').addClass 'hide' if not @model.id
			$container = @$('.canvas')
			@paper = new Raphael $container[0], 256, 256
			@paper.setViewBox 0, 0,
				@model.get('viewBoxWidth') or 0, @model.get('viewBoxHeight') or 0, true
			@paper.add @model.get('strokes')

		_goToTreePage: ->
			app.go @model.id

	class Tree.Views.ShareWidgets extends Backbone.View
		className: "share_widgets well"

		events:
			"click a": "_nullifyHyperlink"

		_addContainer = ($container, networkName) ->
			$("<div class='#{networkName}'></div>").appendTo $container

		_renderShareButtons = ->
			url = 'http://lightmytree.org/' + @model.id

			text = "Don't try to guess my dream gift this year! Instead, I'd rather you decorate my virtual tree with charitable gifts."

			@$('.twitter').sharrre
				share: twitter: yes
				enableHover: no
				enableTracking: yes
				buttons:
					twitter:
						url: url
						via: 'LightMyTree'
				text: text
				title: 'Tweet'
				click: (api, options) ->
					api.simulateClick()
					api.openPopup('twitter')

			@$('.facebook').sharrre
				share: facebook: yes
				enableHover: no
				enableTracking: yes
				buttons:
					facebook:
						url: url
				# text: text
				title: 'Like'
				click: (api, options) ->
					api.simulateClick()
					api.openPopup('facebook')

			# @$('.pinterest').sharrre
			# 	share: pinterest: yes
			# 	enableHover: no
			# 	enableTracking: yes
			# 	# text: 'Some text'
			# 	title: 'Pin'
			# 	enableCounter: no
			# 	# urlCurl: ''
			# 	url: url
			# 	# media: ''
			# 	description: ''
			# 	layout: 'vertical'
			# 	click: (api, options) ->
			# 		api.simulateClick()
			# 		api.openPopup('pinterest')

			@$('.googlePlus').sharrre
				share: googlePlus: yes
				enableHover: no
				enableTracking: yes
				buttons:
					googlePlus:
						url: url
				# text: text
				title: '+1'
				enableCounter: yes
				urlCurl: ''
				click: (api, options) ->
					api.simulateClick()
					api.openPopup('googlePlus')

		_addPostedToWallNotification = ($container) ->
			notice = '<p><span class="label label-info">Note</span> '+
				'Your drawing will be posted to your Facebook wall.</p>'
			$(notice).appendTo $container

		initialize: (options = {}) ->
			@_debouncedRenderShareButtons = _.debounce _renderShareButtons.bind(@), 300, no
			@showPublishGraphActionNotice = options.showPublishGraphActionNotice or no
			# @model.on 'change:id change:_id', @render, @

		beforeRender: ->
			@$el.empty()
			_addContainer @$el, 'twitter'
			_addContainer @$el, 'facebook'
			_addContainer @$el, 'googlePlus'
			if @showPublishGraphActionNotice and @model.get 'publishGraphAction'
				_addPostedToWallNotification @$el

		afterRender: ->
			@_debouncedRenderShareButtons()

		_nullifyHyperlink: (ev) ->
			ev.preventDefault()
			false

	Tree
