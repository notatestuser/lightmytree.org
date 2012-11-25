{TreeDatabase} = require '../database'

fs      = require 'fs'
raphael = require 'node-raphael'
gm      = require 'gm'

module.exports = (app, config) ->

	console.log "Defining IMAGE routes"

	treeDb = new TreeDatabase config

	wrapError = (res, callback) ->
		(err, doc) ->
			if err
				console.trace 'wrapError'
				res.send "Something awful happened", 500
			else
				callback? doc

	# /img/trees/:id.svg
	app.get /^\/img\/trees\/([a-zA-Z0-9_.\- %]+)\.svg$/, (req, res) ->
		treeId = req.params[0] if req.params?
		if treeId
			treeDb.findById treeId, wrapError res, (treeDoc) ->
				if not treeDoc
					res.send "Not found", 404
				else
					res.writeHead 200, {"Content-Type": "image/svg+xml"}
					svg = raphael.generate treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, (paper) ->
						paper.setViewBox(0, 0, treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, true)
						paper.add(treeDoc.strokes)
					res.end svg.replace('svg style="', 'svg style="background-color:#FEFDF8;')

	# /img/trees/:id.:ext
	app.get /^\/img\/trees\/([a-zA-Z0-9_.\- %]+)\.([a-z]{3})$/, (req, res) ->
		treeId  = decodeURIComponent req.params[0] if req.params?
		fileExt = req.params[1]
		width   = Math.min req.param('width', 250), 1000

		# only permit streaming of jpg and png images
		if fileExt isnt 'png' and fileExt isnt 'jpg'
			return res.send "Unsupported image extension; try png or jpg", 500

		if treeId
			treeDb.findById treeId, wrapError res, (treeDoc) ->
				if not treeDoc
					res.send "Not found", 404
				else
					imgFilename = "#{width}.#{fileExt}"

					if treeDoc._attachments?[imgFilename]? and treeDoc._attachments[imgFilename].length?
						# the file already exists in the database - just stream it out!
						res.contentType "image/#{fileExt}"
						stream = treeDb.db.getAttachment treeDoc._id, imgFilename
						stream.addListener 'response', (response) ->
							res.headers = response.headers
							res.headers.status = response.statusCode
						stream.addListener 'data', (chunk) -> res.write(chunk, 'binary')
						stream.addListener 'end', -> res.end()

					else
						# generate the svg
						svg = raphael.generate treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, (paper) ->
							paper.setViewBox(0, 0, treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, true)
							bg = paper.rect(0, 0, treeDoc.viewBoxWidth, treeDoc.viewBoxHeight)
							bg.attr fill: '#FEFDF8'
							paper.add(treeDoc.strokes)
						buf = new Buffer svg

						svgFilename = (time = (new Date()).getTime()) + '.svg'

						# write out the svg
						fs.writeFile svgFilename, buf, (err) ->
							if err
								console.error err
							else
								# call on graphicsmagick to convert our svg to a raster image
								gm(svgFilename).scale(width, 1500).quality(80).stream fileExt, (err, stdout, stderr) ->
									# open up a stream to our attachment
									stream = treeDb.db.saveAttachment(
										treeDoc,
											name: imgFilename
											contentType: "image/#{fileExt}"
											# body: fs.createReadStream(outfile)
										, (err, data) ->
											console.log err if err
											fs.unlink svgFilename
									)
									res.contentType "image/#{fileExt}"
									stdout.pipe(stream)
									stdout.pipe(res)
