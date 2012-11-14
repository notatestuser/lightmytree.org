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

	class Charity.Collection extends Backbone.Collection
		model: Charity.Model
		cache: yes

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
			@collection.forEach (charityModel) ->
				@hasViews = yes
				view = new Charity.Views.Item
					model: charityModel
				view.on 'selected', ->
					treeModel.addCharity view.model
				view.on 'unselected', ->
					treeModel.removeCharity view.model
				if _(@treeModel.get('charityIds')).contains view.model.id
					view.renderSelected()
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
		template: "charity/list_item"
		className: "span3 thumbnail"
		tagName: "li"

		events:
			"click": "toggleSelected"

		serialize: ->
			@model.toJSON()

		renderSelected: ->
			@selected = yes
			@$el.addClass 'selected'
			@$("input").prop('checked', true)

		renderUnselected: ->
			@selected = no
			@$el.removeClass 'selected'
			@$("input").prop('checked', false)

		toggleSelected: ->
			if not @selected
				@trigger('selected')
				@renderSelected()
			else
				@trigger('unselected')
				@renderUnselected()

		afterRender: ->
			if @selected then @renderSelected() else @renderUnselected()


	Charity
