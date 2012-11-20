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
	app.get /^\/img\/trees\/([a-zA-Z0-9_.-]+)\.svg$/, (req, res) ->
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
	app.get /^\/img\/trees\/([a-zA-Z0-9_.-]+)\.png$/, (req, res) ->
		treeId = req.params[0] if req.params?
		if treeId
			treeDb.findById treeId, wrapError res, (treeDoc) ->
				if not treeDoc
					res.send "Not found", 404
				else
					svg = raphael.generate treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, (paper) ->
						paper.setViewBox(0, 0, treeDoc.viewBoxWidth, treeDoc.viewBoxHeight, true)
						bg = paper.rect(0, 0, treeDoc.viewBoxWidth, treeDoc.viewBoxHeight)
						bg.attr fill: "#FEFDF8"
						paper.add(treeDoc.strokes)
					buf = new Buffer svg
					filename = (time = (new Date()).getTime()) + '.svg'
					outfile  =  time + '.png'
					fs.writeFile filename, buf, (err) ->
						console.error err if err
						gm(filename).scale(250,1000).write outfile, (err) ->
							console.error err if err
							res.sendfile outfile, ->
								fs.unlink filename
								fs.unlink outfile
