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
#   sign-ups [timeframe] - shows the number of sign-ups for timeframe
#
# Author:
#   fpe

Keen = require 'keen-js'


module.exports = (robot) ->

  keenClient = new Keen(
    projectId: process.env.KEEN_PROJECT_ID
    readKey:  process.env.KEEN_READ_KEY
    masterKey:  process.env.KEEN_MASTER_KEY
  )

  robot.respond /sign[\s-]?ups (.*)/i, (msg) ->

    timeframe = msg.match[1]
    countSignUps = new Keen.Query "count",
      eventCollection: "Marketsite-TryOutSubmited"
      timeframe: timeframe

    keenClient.run countSignUps, (err, res) ->
      if err
        console.log 'Keen error:', err
        if err.code == "TimeframeDefinitionError"
          msg.send "
          You used a timeframe I can't understand, please use
          a relative time frame from
          https://keen.io/docs/data-analysis/timeframe/"
      else
        msg.send "We had #{res.result} sign-ups #{timeframe}"
