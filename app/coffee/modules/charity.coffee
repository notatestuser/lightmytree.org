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
		initialize: ->
			app.waitForUrl 'recent_charities', (urlFn) =>
				@url = urlFn()
				@fetch()


	class Charity.Views.Picker extends Backbone.View
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


	class Charity.Views.Item extends Backbone.View
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
