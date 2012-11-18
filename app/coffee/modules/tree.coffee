define [
	"app"
	"lodash"
	"backbone"
	"raphael"
	"modules/charity"
	"modules/donation"
	"modules/modal"
	"plugins/raphael.sketchpad"
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
			viewBoxWidth: 600
			viewBoxHeight: 500

		initialize: ->
			@charities = new Charity.Collection()
			@donations = new Donation.Collection()

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

	class Tree.MyModel extends Tree.Model
		@MaxCharities: 4

		url: -> "/json/my_tree"

		initialize: ->
			@remotePersist = false
			super()
			@on 'change:strokes change:charityIds', (model) ->
				console.log "#{(model.get('strokes')).length} stroke(s)"
				model.save()

		sync: (method, model, options, first = true) ->
			defaultSyncFn = ->
				Backbone.sync method, model, options

			# intercept sync() attempt with localStorage persistence
			switch method
				when "create", "update"
					res = $.jStorage.set Tree.Model.LocalStorageKey, @toJSON()
					if @remotePersist
						defaultSyncFn()
					else
						options.success model, res, options
				when "read"
					try
						model.set $.jStorage.get(Tree.Model.LocalStorageKey, {})
					catch ex
						console.error "Gracefully handling Tree.Model.sync() exception"
					if app.authed
						defaultSyncFn()
					else
						options.success model, true, options
				when "delete"
					$.jStorage.deleteKey Tree.Model.LocalStorageKey

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

	class Tree.Views.Save extends Backbone.View
		template: "tree/save"
		className: "tree-save-view"

		events:
			"click .btn-save": "save"

		save: ->
			# @$('.btn-save').button 'loading'
			@model.remotePersist = yes if app.authed
			@model.save()
			if not app.authed
				(new Modal.Views.Authenticate()).show()
			else
				app.router.go 'my_trees'

	class Tree.Views.Share extends Backbone.View
		template: "tree/share"
		className: "tree-share-view"

		serialize: ->
			@model.toJSON()

		afterRender: ->
			if app.authed
				view = new Tree.Partials.ShareLoggedIn()
				@model.remotePersist = yes
				@model.save()
			else
				view = new Tree.Partials.ShareNotLoggedIn
					model: @model
			@setView(".comment_section", view).render()

	class Tree.Partials.ShareLoggedIn extends Backbone.View
		template: "tree/share/logged_in"

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
				@paper.add self.model.get('strokes')
			else
				new Raphael $container[0], $container.width(), $container.height(), ->
					self.paper = @
					@setViewBox 0, 0,
						self.model.get('viewBoxWidth'), self.model.get('viewBoxHeight'), true
					@add self.model.get('strokes')

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

		beforeRender: ->
			@collection.on 'reset', =>
				@render()

			# TODO: dynamically create rows to prevent padding issues?
			@collection.forEach (treeModel) ->
				treeModel.fetch
					success: (model) =>
						@insertView new Tree.Views.Item
							model: treeModel
						.render()
			, @

	class Tree.Views.Item extends Backbone.View
		template: "tree/list_item"
		tagName: "li"
		className: "mini-tree-view span4"

		serialize: -> id: @model.id

		afterRender: ->
			if @options and @options.hideButtons
				@$('.buttons').hide()

			self = @
			$container = @$el
			new Raphael $container[0], 256, 256, ->
				@setViewBox 0, 0,
					self.model.get('viewBoxWidth') or 0, self.model.get('viewBoxHeight') or 0, true
				@add self.model.get('strokes')

	Tree
