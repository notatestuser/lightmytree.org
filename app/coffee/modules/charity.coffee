define [
	"app", "backbone"
],

(app, Backbone) ->

	Charity = app.module()

	class Charity.Model extends Backbone.Model
		idAttribute: 'charityId'
		defaults:
			charityId: 0
			description: ''
			logoFileName: ''
			name: 'Default Charity'
			registrationNumber: 0
			allowSelection: yes
			selected: no
			remainingSelections: -1

	class Charity.Collection extends Backbone.Collection
		model: Charity.Model
		cache: yes

		# TODO: get from the URL gathering function in app
		url: "https://api-sandbox.justgiving.com/" +
			"e90e23e0" +
			"/v1/charity"

	class Charity.RecentCharitiesCollection extends Charity.Collection
		url: "/json/recent_charities"

		initialize: ->
			# TODO are we sure we'd like to fetch on init?
			@fetch()

	class Charity.TypeaheadCollection extends Charity.Collection
		url: "/json/typeahead_charities"

		getSource: ->
			@map (charity) -> charity.get 'name'

	class Charity.SearchCollection extends Charity.Collection
		@ItemsPerFetch: 4

		isResultsCollection: yes

		url: -> # TODO: get from the URL gathering function in app
			"https://api-sandbox.justgiving.com/" +
			"e90e23e0" +
			"/v1/charity/search" +
			"?q=" + @query +
			"&pageSize=" + SearchCollection.ItemsPerFetch +
			"&page=" + @page

		initialize: (options) ->
			@query = options.query or ''
			@pageSize = 4
			@page = 1

		parse: (docs) ->
			[ @totalPages, @hits ] = [ docs.totalPages, docs.numberOfHits ]
			docs.charitySearchResults or []

	class Charity.Views.Picker extends Backbone.View
		template: "charity/picker"
		tagName: "div"

		# events:
		# 	"keypress .search-charities-typeahead": "startSearch"

		initialize: (options) ->
			@treeModel = options.treeModel if options.treeModel
			@typeaheadCharities = options.typeaheadCharities if options.typeaheadCharities

		beforeRender: ->
			treeModel = @treeModel
			# listen for changes to remainingSelections; disable selection if 0
			@collection.on 'change:remainingSelections', (model, remainingSelections) =>
				if remainingSelections is 0 and not @weDisabled
					@weDisabled = yes
					_.invoke @collection.where(selected: no), 'set',
						allowSelection: no
						remainingSelections: remainingSelections
				else if remainingSelections > 0 and @weDisabled
					@weDisabled = no
					_.invoke @collection.where(allowSelection: no), 'set',
						allowSelection: yes
						remainingSelections: remainingSelections

			# iterate over the list of models and create & render our views
			@collection.forEach (charityModel) ->
				@hasViews = yes
				view = new Charity.Views.Item
					model: charityModel
				view.on 'selected', ->
					# calling this method will deal with setting 'selected' for us
					treeModel.addCharity view.model
				view.on 'unselected', ->
					treeModel.removeCharity view.model
				treeModel.setInitialCharityState view.model
				@insertView '.charities', view
			, @

		afterRender: ->
			if @collection.isResultsCollection
				# make us a list of 'results', render pagination and such
				@$('.charities').addClass 'results' if @collection.isResultsCollection
				@setView '.pagination-holder', new Charity.Partials.Pagination
					collection: @collection
				.render()
			@typeaheadCharities.on 'reset', =>
				@$('.search-charities-typeahead').typeahead
					source: @typeaheadCharities.getSource()
					updater: (item) =>
						@startSearch item
						item
			.fetch()

		startSearch: (query) ->
			@collection = new Charity.SearchCollection
				query: query
			@collection.fetch
				success: => @render()
			@collection.on 'reset', @render, @

	class Charity.Partials.Pagination extends Backbone.View
		@PageCap: 9

		className: "row-fluid pagination"

		clearEvents = ->
			@undelegateEvents()
			@events = {}

		handleClick = (label) ->
			if @collection.page isnt label
				if label is 'Next'
					@collection.page++
				else if label is 'Prev'
					@collection.page--
				else
					@collection.page = label
				@collection.fetch()
			false

		addResultsCounter = ->
			$("<li class=\"disabled\"><span>#{@collection.hits} results</span></li>").appendTo @$ul

		addPages = ->
			addItem = (label, wireEvent = yes) =>
				tag = if wireEvent then 'a' else 'span'
				clazz = "pg-#{label}"
				liAttr = "class=\"active\"" if @collection.page is label
				$("<li #{liAttr or ''}><#{tag} href=\"#\" class=\"#{clazz}\">#{label}</#{tag}></li>")
					.appendTo @$ul
				@events["click .#{clazz}"] = handleClick.bind @, label if wireEvent

			curPage = @collection.page
			endPage = if curPage + 4 > Pagination.PageCap then Math.min(curPage + 4, @collection.totalPages) else Pagination.PageCap
			startPage = Math.max(endPage - (Pagination.PageCap - 1), 1)

			addItem 'Prev' if curPage isnt 1
			addItem '...', no if startPage > 1
			addItem i for i in [startPage..endPage]
			addItem '...', no if endPage < @collection.totalPages
			addItem 'Next' if curPage isnt @collection.totalPages

		initialize: ->
			clearEvents.call @

		beforeRender: ->
			@$ul.remove() if @$ul
			@$ul = $("<ul></ul>").appendTo @$el
			addResultsCounter.call @
			clearEvents.call @
			addPages.call @
			@delegateEvents()

	class Charity.Views.Item extends Backbone.View
		@JGImagePath: '/Utils/imaging.ashx?width=80&height=80&square=80&imageType=charitybrandinglogo&img='

		template: "charity/list_item"
		className: "span3 thumbnail"
		tagName: "li"

		events:
			"click .select-checkbox": "toggleSelected"
			"click .revealer": "revealDescription"

		initialize: ->
			@model.on 'change:selected change:allowSelection', @render, @

		serialize: ->
			obj = @model.toJSON()
			_.extend obj, logoFileName: Item.JGImagePath + url if url = @model.get 'logoUrl'
			obj

		afterRender: ->
			if @model.get 'selected'
				@renderSelected()
			else
				@renderUnselected()
			if not @model.get 'allowSelection'
				@renderDisabled()

		renderSelected: ->
			@$el.addClass 'selected'
			@$('input').prop('checked', true)
			if @model.get('remainingSelections') >= 0
				@$('.limit-warning')
					.addClass('show')
					.delay(1500)
					.slideUp(1000)

		renderUnselected: ->
			@$el.removeClass 'selected'
			@$('input').prop('checked', false)
			@$('.limit-warning').removeClass 'show'

		renderDisabled: ->
			@$('.select-checkbox').html 'Your wish list is full!'

		toggleSelected: ->
			# have the Picker handle this for us - it involves moving things around in the Tree
			if not @model.get 'selected'
				@trigger('selected')
			else
				@trigger('unselected')

		revealDescription: ->
			@$('.revealer').fadeOut 'fast', =>
				@$('.description').removeClass 'contracted'

	class Charity.Views.MiniItem extends Charity.Views.Item
		template: "charity/list_item_mini"
		className: "thumbnail mini"

	Charity
