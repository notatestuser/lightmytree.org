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

	# /img/trees/:id.png
	app.get /^\/img\/trees\/([a-zA-Z0-9_.\- %]+)\.png$/, (req, res) ->
		treeId = req.params[0] if req.params?
		width  = Math.min req.param('width', 250), 1000
		if treeId
			treeDb.findById treeId, wrapError res, (treeDoc) ->
				if not treeDoc
					res.send "Not found", 404
				else
					pngFilename = "#{width}.png"

					if treeDoc._attachments?.hasOwnProperty pngFilename
						# the file already exists in the database - just stream it out!
						res.contentType 'image/png'
						stream = treeDb.db.getAttachment treeDoc._id, pngFilename
						stream.addListener 'response', (response) ->
							res.headers = response.headers
							res.headers.status = response.statusCode
							# res.body = ""
						stream.addListener 'data', (chunk) -> res.write(chunk, 'binary')
						stream.addListener 'end', -> res.end()

					else
						# generate the svg
						svg = raphael.generate treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, (paper) ->
							paper.setViewBox(0, 0, treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, true)
							bg = paper.rect(0, 0, treeDoc.viewBoxWidth, treeDoc.viewBoxHeight)
							bg.attr fill: "#FEFDF8"
							paper.add(treeDoc.strokes)
						buf = new Buffer svg

						svgFilename = (time = (new Date()).getTime()) + '.svg'
						# out file  =  time + '.png'

						# write out the svg
						fs.writeFile svgFilename, buf, (err) ->
							if err
								console.error err
							else
								# call on graphicsmagick to convert our svg to a png
								gm(svgFilename).scale(width, 1500).stream 'png', (err, stdout, stderr) ->
									# open up a stream to our attachment
									stream = treeDb.db.saveAttachment(
										treeDoc,
											name: pngFilename
											contentType: 'image/png'
											# body: fs.createReadStream(outfile)
										, (err, data) ->
											console.log err if err
											fs.unlink svgFilename
									)
									res.contentType 'image/png'
									stdout.pipe(stream)
									stdout.pipe(res)
