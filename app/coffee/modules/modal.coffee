define [
	"app", "backbone"
],

(app, Backbone) ->

	Modal = app.module()

	# most of this hacks around the fact that things weren't working exactly as expected -
	# Bootstrap couldn't find the element's parent upon being called to show the modal and thus
	# decided to attempt to append it to the body while missing out contained elements...
	# I figured it's something to do with the scoped jquery selector but whatever, life is short

	class Modal.Views.Base extends Backbone.View
		className: "modal hide fade"
		uniqueName: "modal-views-base"

		afterRender: ->
			$('.'+@uniqueName).remove()
			@$el
				.detach()
				.prependTo('body')
				.addClass(@uniqueName)

		show: ->
			$('.'+@uniqueName).modal()

	class Modal.Views.Authenticate extends Modal.Views.Base
		template: "modals/authenticate"
		uniqueName: "modal-views-authenticate"

	class Modal.Views.FourOhFour extends Modal.Views.Base
		template: "modals/404"
		uniqueName: "modal-views-404"


	Modal
