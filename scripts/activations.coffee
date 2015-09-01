# Description:
#   Keeps track of our activations
#
# Dependencies:
#   "keen-js": "^3.2.1"
#
# Commands:
#   hubot activations <time frame> - shows the number of activations for time frame. Avialable time frames can be found here: https://keen.io/docs/data-analysis/timeframe/ Examples: Today, Yesterday, last_2_months, this_week
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

  timeFrameErrorMsg = "You used a time frame I can't understand,
  please use a relative time frame from
  https://keen.io/docs/data-analysis/timeframe/ \n
  Examples: Today, Yesterday, last_2_months, this_week"

  # Handels sign-ups
  robot.respond /activations ?(.*)/i, (msg) ->

    timeframe = if msg.match[1] then msg.match[1] else "today"
    countActivations = new Keen.Query "count",
      eventCollection: "Sales-DealStatusChange"
      filters:[{"operator":"contains","property_name":"deal.status","property_value":"Testkonto"},{"operator":"contains","property_name":"deal.tags","property_value":"auto signup"}]
      timeframe: timeframe
      timezone: "Europe/Stockholm"

    keenClient.run countActivations, (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        msg.send "We had #{res.result} activations #{timeframe.replace('_',' ')}"
