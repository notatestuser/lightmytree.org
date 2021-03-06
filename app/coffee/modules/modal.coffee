define [
	"app", "backbone"
	"bootstrap/bootstrap-modal"
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
		tagName: "div"

		afterRender: ->
			$('.'+@uniqueName).remove()
			@$el
				.detach()
				.prependTo('#main')
				.addClass(@uniqueName)
			@show() if @showAfterRender

		show: ->
			$('.'+@uniqueName).modal()

		closeModal: ->
			$('.'+@uniqueName).modal 'hide'

	class Modal.Views.Authenticate extends Modal.Views.Base
		template: "modals/authenticate"
		uniqueName: "modal-views-authenticate"

	class Modal.Views.FourOhFour extends Modal.Views.Base
		template: "modals/404"
		uniqueName: "modal-views-404"

	class Modal.Views.DonateRedirect extends Modal.Views.Base
		template: "modals/donate_redirect"
		uniqueName: "modal-donate-redirect"

		initialize: (options) ->
			@url = options.url or '#'
			@processorName = options.processorName or 'our payment processor'
			@showAfterRender = yes

		serialize: ->
			{ url: @url, processorName: @processorName }

	class Modal.Views.Donated extends Modal.Views.Base
		template: "modals/donated"
		uniqueName: "modal-donated"

		events:
			"click .btn-close": "closeModal"

		initialize: ->
			@showAfterRender = yes


	Modal
