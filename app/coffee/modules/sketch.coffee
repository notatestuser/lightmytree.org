define [
	"app"
	"lodash"
	"backbone"
	"bootstrap/bootstrap-tooltip"
],

(app, _, Backbone) ->

	Sketch = app.module()

	class Sketch.Model extends Backbone.Model
		defaults:
			pencilWidth: 5
			pencilColour: '#000000'
			pencilOpacity: 1
			erasing: no

		initialize: (options) ->
			if options.tree
				options.tree.fetch()
				@set('tree', options.tree)

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

	class Sketch.Views.EraserPanel extends Backbone.View
		template: "sketch/eraser-panel"
		className: "eraser-panel-view"

		events:
			"click .eraser": "_toggleErasing"
			"click .btn-undo": "_attemptUndo"
			"click .btn-redo": "_attemptRedo"

		initialize: ->
			@model.on 'change:erasing', @_changeErasing

		afterRender: ->
			@$eraser = @$('.eraser')
			@$('.btn-undo').tooltip
				title: 'Undo last stroke'
				placement: 'top'
			@$('.btn-redo').tooltip
				title: 'Repeat stroke'
				placement: 'bottom'
			@$eraser.tooltip
				title: 'Erase lines (click to erase)'
				placement: 'top'

		_toggleErasing: ->
			erasing = @model.get 'erasing'
			@model.set
				erasing: not erasing
				pencilColour: '#000001'

		_changeErasing: (model, erasing) =>
			if erasing
				@$eraser.addClass 'selected'
			else
				@$eraser.removeClass 'selected'

		_attemptUndo: ->
			@model.trigger 'undo'

		_attemptRedo: ->
			@model.trigger 'redo'

	class Sketch.Views.Toolkit extends Backbone.View
		template: "sketch/tools"
		className: "sketchpad-tools span12"

		@PencilWidths = [ 2, 5, 10, 15 ]
		@PencilOpacities = [ 0.25, 0.5, 0.75, 1 ]

		initialize: (options) ->
			@pencilFloat = options.pencilFloat or 'left'

		afterRender: ->
			for width in Toolkit.PencilWidths
				@insertView '.thickness-buttons', new Sketch.Views.PencilWidth
					model: @model
					width: width
				.render()
			for opacity in Toolkit.PencilOpacities
				@insertView '.opacity-buttons', new Sketch.Views.PencilOpacity
					model: @model
					opacity: opacity
				.render()
			for i in [0..4]
				@insertView '.pencil-case', new Sketch.Views.Pencil
					model: @model
					position: i
					pencilFloat: @pencilFloat
				.render()

	class Sketch.Views.PencilWidth extends Backbone.View
		className: "thumbnail"

		events:
			"click": "_setThisWidth"

		initialize: (options) ->
			@width = options.width or 10
			@model
				.on('change:pencilColour', @_changePencilColour)
				.on('change:pencilWidth', @_changePencilWidth)
				.on('change:pencilOpacity', @_changePencilOpacity)
				.on('change:erasing', @_changeErasing)

		afterRender: ->
			$('<div class="colour-blob"></div>')
				.width(@width)
				.height(@width)
				.appendTo(@$el)
			@_changePencilColour null, @model.get('pencilColour')
			@_changePencilWidth null, @model.get('pencilWidth')
			# @$el.tooltip
			# 	title: 'Thickness'
			# 	placement: 'top'

		_setThisWidth: ->
			if @width
				@model.set 'pencilWidth', @width

		_changePencilColour: (model, newColour) =>
			@$('.colour-blob').css backgroundColor: newColour

		_changePencilWidth: (model, newWidth) =>
			if newWidth is @width
				@$el.addClass 'selected'
			else
				@$el.removeClass 'selected'

		_changePencilOpacity: (model, newOpacity) =>
			@$('.colour-blob').css opacity: newOpacity

		_changeErasing: (model, newErasing) =>
			if newErasing
				@$el.addClass 'disabled'
			else if not newErasing
				@$el.removeClass 'disabled'

	class Sketch.Views.PencilOpacity extends Sketch.Views.PencilWidth
		events:
			"click": "_setThisOpacity"

		initialize: (options) ->
			super options
			@opacity = options.opacity or 1

		afterRender: ->
			$('<div class="colour-blob"></div>')
				.width(width = @model.get('pencilWidth'))
				.height(width)
				.css('opacity', @opacity)
				.appendTo(@$el)
			@_changePencilColour null, @model.get('pencilColour')
			@_changePencilWidth null, @model.get('pencilWidth')
			@_changePencilOpacity null, @model.get('pencilOpacity')
			# @$el.tooltip
			# 	title: 'Transparency'
			# 	placement: 'bottom'

		_setThisOpacity: ->
			if @opacity
				@model.set 'pencilOpacity', @opacity

		_changePencilWidth: (model, newWidth) =>
			@$('.colour-blob')
				.width(newWidth)
				.height(newWidth)

		_changePencilOpacity: (model, newOpacity) =>
			if newOpacity is @opacity
				@$el.addClass 'selected'
			else
				@$el.removeClass 'selected'

	class Sketch.Views.Pencil extends Backbone.View
		template: "sketch/pencil"
		className: "pencil"

		@Classes = [
			"pencil-red"
			"pencil-blue"
			"pencil-cyan"
			"pencil-green"
			"pencil-darkgreen"
			"pencil-yellow"
			"pencil-purple"
			"pencil-pink"
			"pencil-orange"
			"pencil-black"
		]
		@AvailableClasses = [] # we'll build this up in initialize()

		events:
			"click": "_setThisColour"

		initialize: (options) ->
			@position = options.position or 0
			@pencilFloat = options.pencilFloat or 'left'

			Pencil.AvailableClasses = _.shuffle(Pencil.Classes) if not Pencil.AvailableClasses.length
			@ourClass = Pencil.AvailableClasses.pop() or 'pencil-blue'

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

		_setThisColour: ->
			if @ourColour
				@model.set
					pencilColour: @ourColour
					erasing: no

		_changePencilColour: (model, newColour) =>
			newTop = if newColour is @ourColour then 0 else 200
			@$el.animate top: newTop, 'fast'

	class Sketch.Views.Sketchpad extends Backbone.View
		initialize: ->
			@model
				.on('change:pencilColour', @_changePencilColour)
				.on('change:pencilWidth', @_changePencilWidth)
				.on('change:pencilOpacity', @_changePencilOpacity)
				.on('change:erasing', @_changeErasing)
				.on('undo', @_attemptUndo)
				.on('redo', @_attemptRedo)

		afterRender: ->
			self = @
			$container = @$container = @$el
			# TODO: empty container in beforeRender() and trigger a render() on resizeCanvas event
			new Raphael $container[0], $container.width(), $container.height(), ->
				sketchpad = self.sketchpad = Raphael.sketchpad @,
					strokes: self.model.tree().get('strokes')
				sketchpad.change ->
					self.model.tree().save
						strokes: strokes = sketchpad.strokes()
						viewBoxWidth: $container.width()
						viewBoxHeight: $container.height()
				pen = sketchpad.pen()
				pen.color self.model.get('pencilColour')
				pen.width self.model.get('pencilWidth')

				# bind resize handler here in lieu of watching the element itself
				$(window).resize self.resizeCanvas.bind(self)

		resizeCanvas: ->
			if @$container
				@sketchpad.paper().setSize @$container.width(), @$container.height()

		_changePencilColour: (model, newColour) =>
			@sketchpad.pen().color newColour

		_changePencilWidth: (model, newWidth) =>
			@sketchpad.pen().width newWidth

		_changePencilOpacity: (model, newOpacity) =>
			@sketchpad.pen().opacity newOpacity

		_changeErasing: (model, newErasing) =>
			@sketchpad.editing if newErasing then 'erase' else yes

		_attemptUndo: =>
			@sketchpad.undo() if @sketchpad and @sketchpad.undoable()

		_attemptRedo: =>
			@sketchpad.redo() if @sketchpad and @sketchpad.redoable()

	Sketch
