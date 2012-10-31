define [
	"app", "backbone"
],

(app, Backbone) ->

	Charity = app.module()

	Charity.Model = Backbone.Model.extend
		idAttribute: 'charityId'
		defaults:
			charityId: 0
			description: ''
			logoFileName: ''
			name: 'Default Charity'
			registrationNumber: 0

	Charity.Collection = Backbone.Collection.extend
		model: Charity.Model
		cache: yes

	Charity.RecentCharitiesCollection = Charity.Collection.extend
		initialize: ->
			app.waitForUrl 'recent_charities', (urlFn) =>
				@url = urlFn()
				@fetch()

	Charity.Views.Picker = Backbone.View.extend
		template: "charity/picker"
		className: "thumbnails"
		tagName: "ul"

		initialize: (options) ->
			@treeModel = options.treeModel if options.treeModel

		beforeRender: ->
			treeModel = @treeModel
			@collection.forEach (charityModel) ->
				view = new Charity.Views.Item
					model: charityModel
				view.on 'selected', ->
					treeModel.charities.push view.model
				view.on 'unselected', ->
					treeModel.charities.remove treeModel.charities.get(view.model.id)
				@insertView view
			, @

	Charity.Views.Item = Backbone.View.extend
		template: "charity/list_item"
		className: "span3 thumbnail"
		tagName: "li"

		events:
			"click input": "toggleSelected"

		serialize: ->
			@model.toJSON()

		toggleSelected: ->
			if @$("input").is(":checked")
				@trigger('selected')
				@$el.css('background-color', 'lightgreen')
			else
				@trigger('unselected')
				@$el.css('background-color', 'transparent')

	Charity
