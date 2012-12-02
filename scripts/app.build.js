({
	baseUrl: "js",
	appDir: "../assets",
	dir: "../assets_live",

	mainConfigFile: "../assets/js/config.js",

	optimize: "uglify",
	optimizeCss: "standard",
	removeCombined: true,

	// https://github.com/jrburke/almond
	name: "libs/almond",
	// out: "libs/require",
	include: [ "main" ],
	// insertRequire: [ "config" ],
	wrap: true,

	paths: {
		require: ':empty'
	}
})
