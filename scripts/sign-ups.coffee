# Description:
#   Keeps track of our sign-ups
#
# Dependencies:
#   "keen-js": "^3.2.1"
#
# Commands:
#   hubot sign-ups <time frame> - shows the number of sign-ups for time frame. Avialable time frames can be found here: https://keen.io/docs/data-analysis/timeframe/ Examples: Today, Yesterday, last_2_months, this_week
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



  # Handels goals for Sign-ups
  robot.respond /sign[\s-]?up goals ?(.*)/i, (msg) ->
    timeframe = if msg.match[1] then msg.match[1] else "today"
    sumGoals = new Keen.Query "sum",
      eventCollection: "Goal-signups-daily-weekendcompensated"
      targetProperty: "day_goal"
      timeframe: timeframe
      timezone: "Europe/Stockholm"

    keenClient.run sumGoals, (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        msg.send "The goal for #{timeframe.replace('_',' ')} was #{res.result.toFixed(1)} sign-ups"


  # Handels sign-ups
  robot.respond /sign[\s-]?ups ?(.*)/i, (msg) ->

    timeframe = if msg.match[1] then msg.match[1] else "today"
    countSignUps = new Keen.Query "count",
      eventCollection: "Marketsite-TryOutSubmited"
      timeframe: timeframe
      timezone: "Europe/Stockholm"

    keenClient.run countSignUps, (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        msg.send "We had #{res.result} sign-ups #{timeframe.replace('_',' ')}"

  # Handels activation count
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

  # Handels activation count
  robot.respond /conversions ?(.*)/i, (msg) ->

    timeframe = if msg.match[1] then msg.match[1] else "today"
    human_timefram = timeframe.replace("_", " ")
    countActivations = new Keen.Query "count",
      eventCollection: "Sales-DealStatusChange"
      filters:[{"operator":"contains","property_name":"deal.status","property_value":"Testkonto"},{"operator":"contains","property_name":"deal.tags","property_value":"auto signup"}]
      timeframe: timeframe
      timezone: "Europe/Stockholm"

    countSignUps = new Keen.Query "count",
      eventCollection: "Marketsite-TryOutSubmited"
      timeframe: timeframe
      timezone: "Europe/Stockholm"

    keenClient.run [countSignUps, countActivations], (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        signups = res.data[0]
        activation = res.data[1]
        if signups > 0
          conversion_rate = Math.round((activation / signups) * 100)
          msg.send "#{human_timefram} we had #{signups} sign-ups and #{activation} activations, giving us an conversion rate of #{conversion_rate}%"
        else
          msg.send "Sorry, we didn't have a single sign-up #{human_timefram}"
