# Description:
#   Keeps track of our sign-ups
#
#   Set the environment variable HUBOT_SHIP_EXTRA_SQUIRRELS (to anything)
#   for additional motivation
#
# Dependencies:
#   None
#
# Commands:
#   sign-ups - shows the number of sign-ups for today
#
# Author:
#   fpe

Keen = require 'keen-js'


module.exports = (robot) ->

  keenClient = new Keen(
    projectID: process.env.KEEN_PROJECT_ID
    readKey:  process.env.KEEN_READ_KEY
    masterKey:  process.env.KEEN_MASTER_KEY
  )

  robot.respond /sign-ups today/i, (msg) ->
    console.log 'Checking for sign-ups for today'
    countSignUps = new Keen.Query "count",
      eventCollection: "Marketsite-TryOutSubmited"
      timeframe: "today"

    msg.send keenClient.run countSignUps, (err, res) ->
      if err
        console.log 'Keen error'
      else
        console.log "We have #{res.result} sign-ups today"
        return "We have #{res.result} sign-ups today"
