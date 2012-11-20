### require modules ###
express = require 'express'
espresso = require './espresso'
stylus = require 'stylus'
nib = require 'nib'

### create express server ###
app = express.createServer()

### parse args (- coffee and the filename) ###
ARGV = process.argv[2..]
rargs = /-{1,2}\w+/
rprod = /-{1,2}(p|production)/

for s in ARGV
	m = rargs.exec s
	app.env = 'production' if m and m[0] and m[0].match rprod

### environment configuration ###
if app.env isnt 'production'
	console.log "Welcome to development mode"
	apiRoutes = './routes/fixtures'
	envConfig = require './configs/development'
else
	console.log "Welcome to production mode"
	apiRoutes = './routes/api'
	envConfig = require './configs/production'

### stylus compilation func ###
compile = (str, path) ->
	stylus(str)
	.set('filename', path)
	.set('compress', true)
	.use(nib())

### init authentication ###
everyauth = require('./authentication')(envConfig)

### express configuration ###
app.configure ->
	app.set 'views', __dirname + '/views'
	app.set 'view engine', 'jade'
	app.use express.bodyParser()
	app.use stylus.middleware
		src: __dirname
		dest: __dirname + '/../assets'
		compile: compile
	app.use express.static __dirname + '/../assets'
	app.use express.cookieParser()
	app.use express.session secret: envConfig.sessionSecret
	app.use everyauth.middleware()
	app.use express.errorHandler()

### watch coffeescript sources ###
coffee = espresso.core.exec 'coffee -o ../assets/js -w -c coffee'
coffee.stdout.on 'data', (data) ->
	espresso.core.minify() if app.env == 'production'

### watch stylus sources ###
# espresso.core.exec 'stylus -w -c styl -o ../assets/css'

### app routes ###
require('./routes/data') app, envConfig
require('./routes/images') app, envConfig
require(apiRoutes) app, envConfig

og = require('./opengrapher') app, envConfig

app.get '/*', og (req, res, og) ->
	res.render 'index',
		title : 'LightMyTree'
		loggedIn: req.loggedIn
		user: req.user
		openGraphObject: og

### start server ###
app.listen 3000, ->
	espresso.core.logEspresso()
	console.log "Server listening on port %d, %s", app.address().port, app.env
