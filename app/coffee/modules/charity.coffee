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

		initialize: (options = {}) ->
			@query = options.query or ''

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
		url: -> # TODO: get from the URL gathering function in app
			"https://api-sandbox.justgiving.com/e90e23e0/v1/charity/search?q=" + @query

		parse: (docs) ->
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
