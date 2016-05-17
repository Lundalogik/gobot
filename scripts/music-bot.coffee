SpotifyWebApi = require('spotify-web-api-node')
credentianls = {clientId:'d721f2dd300647b4b69287015be5f310', clientSecret:'4b68ccdff9db4e8b91d6f832f5a7b62d'}
spotifyApi = new SpotifyWebApi(credentianls)
spotifyUser = 'kaptendavidsson'

validFeelings = ['happy', 'angry', 'sad']

module.exports = (robot) ->
	robot.respond /list feelings/i, (res) ->
    	res.reply validFeelings.toString()

	
	robot.respond /play something (.*)/i, (res) ->
		feeling = res.match[1]
		if feeling in validFeelings
    		res.reply "Sure thing"
    		getSong(feeling, res)
    	else
    		res.reply "I'm unfamiliar with that feeling"


grantClient = ->
  	spotifyApi.clientCredentialsGrant().then ((data) ->
	    console.log 'Got new access token, valid for', data.expires_in, 'seconds'
	    spotifyApi.setAccessToken data.access_token
	    start = true
	    setTimeout grantClient, data.expires_in * 1000
	    return
  	), (err) ->
    	console.log 'Something went wrong when retrieving an access token', err
    	process.exit 1
    	return
  	return


getSong = (feeling, res) -> 
	spotifyApi.searchTracks(feeling).then ((data) ->
  		res.reply '<a href="' + data.tracks.items[Math.floor(Math.random() * 19)].uri + '"/>'
  		return
	), (err) ->
  		console.error err
  		return
		  
grantClient()