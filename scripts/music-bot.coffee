SpotifyWebApi = require('spotify-web-api-node')
credentianls = {clientId:'d721f2dd300647b4b69287015be5f310', clientSecret:'4b68ccdff9db4e8b91d6f832f5a7b62d'}
spotifyApi = new SpotifyWebApi(credentianls)
spotifyUser = 'kaptendavidsson'
playlists = []
playlists['angry'] = { uri: '7ckOx5njjvQF7LNowYrYjX', owner: 'scawp' }
playlists['sad'] = { uri: '7ABD15iASBIpPP5uJ5awvq', owner: 'sanik007' }
playlists['happy'] = { uri: '4bDTPd2Ykgd89LwEc626pk', owner: 'assiagrazioli' }
playlists['chaotic'] = { uri: '3faHorqT0w0y69cZBrfVkh', owner: 'thesoundsofspotify' }

validFeelings = []
for k of playlists
  validFeelings.push k

module.exports = (robot) ->
  robot.respond /list feelings/i, (res) ->
    res.reply validFeelings.toString()


  robot.respond /I'm feeling (.*) today/i, (res) ->
    feeling = res.match[1]
    if feeling in validFeelings
      res.reply "Try this" 
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
  spotifyApi.getPlaylistTracks(playlists[feeling].owner, playlists[feeling].uri).then ((data) ->
    res.reply '<a href="' + data.items[Math.floor(Math.random() * (data.items.length - 1))].track.uri + '"/>'
    return 
  ), (err) ->
    console.error err
    return

grantClient()