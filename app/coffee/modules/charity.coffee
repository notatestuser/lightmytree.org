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
			# @collection.on 'reset', =>
			# 	@beforeRender() if not @hasViews?

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

		renderSelected: ->
			@selected = yes
			@$el.css('background-color', 'lightgreen')
			@$("input").prop('checked', true)

		renderUnselected: ->
			@selected = no
			@$el.css('background-color', 'transparent')
			@$("input").prop('checked', false)

		toggleSelected: ->
			if @$("input").is(":checked")
				@trigger('selected')
				@renderSelected()
			else
				@trigger('unselected')
				@renderUnselected()

		afterRender: ->
			if @selected then @renderSelected() else @renderUnselected()


	Charity
