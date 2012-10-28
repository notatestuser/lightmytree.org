### require modules ###
express = require 'express'
espresso = require './espresso'

### create express server ###
app = express.createServer()

### parse args (- coffee and the filename) ###
ARGV = process.argv[2..]
rargs = /-{1,2}\w+/
rprod = /-{1,2}(p|production)/

for s in ARGV
	m = rargs.exec s
	app.env = 'production' if m and m[0] and m[0].match rprod

### express configuration ###
app.configure ->
	app.set 'views', __dirname + '/views'
	app.set 'view engine', 'jade'
	app.use express.bodyParser()
	app.use express.static __dirname + '/../assets'


### watch coffeescript sources ###
coffee = espresso.core.exec 'coffee -o ../assets/js -w -c coffee'
coffee.stdout.on 'data', (data) ->
	espresso.core.minify() if app.env == 'production'


### watch stylus sources ###
espresso.core.exec 'stylus -w -c styl -o ../assets/css'


### app routes ###
if app.env isnt 'production'
	require('./routes/fixtures') app
else
	require('./routes/api') app

app.get '/*', (req, res) ->
	res.render 'index', { title : 'LightMyTree' }

### start server ###
app.listen 3000, ->
	espresso.core.logEspresso()
	console.log "Server listening on port %d, %s", app.address().port, app.env
