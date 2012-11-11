define [
	"app"
	"lodash"
	"backbone"
],

(app, _, Backbone) ->

	Sketch = app.module()

	class Sketch.Model extends Backbone.Model
		defaults:
			pencilWidth: 5
			pencilColour: '#000000'

		initialize: (options) ->
			@set('tree', options.tree) if options.tree

		tree: ->
			@get('tree')

	class Sketch.Views.Workspace extends Backbone.View
		template: "sketch/workspace"
		className: "workspace-view"

		initialize: ->
			# @model.on 'change', => @showSavedAlert()

		showSavedAlert: ->
			if not @shownSavedAlert
				@shownSavedAlert = yes
				@$('.alert-saved-container')
					.fadeIn('slow')
					.slideDown('slow')

	class Sketch.Views.Toolkit extends Backbone.View
		template: "sketch/tools"
		className: "sketchpad-tools span12"

		@PencilWidths = [ 1, 5, 10, 15 ]

		initialize: (options) ->
			@pencilFloat = options.pencilFloat or 'left'

		afterRender: ->
			for width in Toolkit.PencilWidths
				@insertView '.pencil-config', new Sketch.Views.PencilWidth
					model: @model
					width: width
				.render()
			for i in [0..4]
				@insertView '.pencil-case', new Sketch.Views.Pencil
					model: @model
					position: i
					pencilFloat: @pencilFloat
				.render()

		selectPencil: (pencil) ->
			console.log arguments

	class Sketch.Views.PencilWidth extends Backbone.View
		className: "thumbnail"

		initialize: (options) ->
			@width = options.width or 10
			@model.on 'change:pencilColour', @_changePencilColour

		afterRender: ->
			$('<div class="colour-blob"></div>')
				.width(@width)
				.height(@width)
				.appendTo(@$el)

		_changePencilColour: (model, newColour) =>
			@$('.colour-blob').css backgroundColor: newColour

	class Sketch.Views.Pencil extends Backbone.View
		template: "sketch/pencil"
		className: "pencil"

		@PencilColours = _.shuffle [
			"pencil-blue"
			"pencil-green"
			"pencil-darkgreen"
			"pencil-yellow"
			"pencil-purple"
			"pencil-pink"
			"pencil-orange"
		]

		events:
			"click": "_selected"

		initialize: (options) ->
			@position = options.position or 0
			@pencilFloat = options.pencilFloat or 'left'
			@ourClass = Pencil.PencilColours.pop() or 'pencil-blue'
			@model.on 'change:pencilColour', @_changePencilColour

		beforeRender: ->
			@$el.addClass @ourClass

		afterRender: ->
			@ourColour = @$('.original-bg').css 'background-color'

			wouldBeOffset = (@position * 35)
			@$el.css
				top: (@$el.parent().outerHeight() - 60)
				zIndex: 100 - (@position * 10)
			@$el.css @pencilFloat, (@position * (@$el.outerWidth() - 1))

			# animate slide out in a little bit
			setTimeout =>
				@$el.animate top: wouldBeOffset, 1500
			, 200

		_selected: ->
			if @ourColour
				@model.set 'pencilColour', @ourColour

		_changePencilColour: (model, newColour) =>
			newTop = if newColour is @ourColour then 0 else 200
			@$el.animate top: newTop, 'fast'

	class Sketch.Views.Sketchpad extends Backbone.View
		initialize: ->
			@model.on 'change:pencilColour', @_changePencilColour

		afterRender: ->
			self = @
			$container = @$container = @$el
			new Raphael $container[0], $container.width(), $container.height(), ->
				sketchpad = self.sketchpad = Raphael.sketchpad @,
					strokes: self.model.tree().get('strokes')
				sketchpad.change ->
					self.model.tree().save
						strokes: strokes = sketchpad.strokes()
						viewBoxWidth: $container.width()
						viewBoxHeight: $container.height()

				# bind resize handler here in lieu of watching the element itself
				$(window).resize self.resizeCanvas.bind(self)

		resizeCanvas: ->
			if @$container
				console.log "New canvas dimensions: #{@$container.width()} #{@$container.height()}"
				@sketchpad.paper().setSize @$container.width(), @$container.height()

		_changePencilColour: (model, newColour) =>
			@sketchpad.pen().color newColour

	Sketch
