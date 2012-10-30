define [
	"app", "backbone"
],

(app, Backbone) ->

	Charity = app.module()

	Charity.Model = Backbone.Model.extend
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
				@url = eval(urlFn)()
				@fetch()

	Charity.Views.Picker = Backbone.View.extend
		template: "charity/picker"
		className: "charity-picker-view"
		tagName: "ul"

		beforeRender: ->
			@collection.forEach (charityModel) ->
				@insertView new Charity.Views.Item
					model: charityModel
			, @

	Charity.Views.Item = Backbone.View.extend
		template: "charity/list_item"
		className: "span3"
		tagName: "li"

		serialize: ->
			@model.toJSON()

	Charity
