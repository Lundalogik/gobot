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

  create_signup_query = (timeframe)->
    return new Keen.Query "count_unique",
      targetProperty: "email"
      eventCollection: "Marketsite-TryOutSubmited"
      timezone: "Europe/Stockholm"
      timeframe: timeframe
      filters:[
        {
          "operator": "not_contains",
          "property_name": "email",
          "property_value": "@lundalogik"
        },
        {
          "operator": "not_contains",
          "property_name": "email",
          "property_value": "@lime-go"
        }
      ]

  create_activations_query = (timeframe) ->
    activations_query = new Keen.Query "count",
      eventCollection: "Sales-DealStatusChange"
      filters:[
        {
          "operator":"contains",
          "property_name":"deal.status",
          "property_value":"Testkonto"},
        {
          "operator":"contains",
          "property_name":"deal.tags",
          "property_value":"auto signup"
        },
        {
          "operator": "not_contains",
          "property_name": "person.email",
          "property_value": "@lundalogik"
        },
        {
          "operator": "not_contains",
          "property_name": "email",
          "property_value": "@lime-go"
        }
      ]
      timezone: "Europe/Stockholm"
      timeframe: timeframe

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

    timeframe = (if msg.match[1] then msg.match[1] else "today").toLowerCase()
    countSignUps = create_signup_query(timeframe)

    keenClient.run countSignUps, (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        msg.send "We had #{res.result} sign-ups #{timeframe.replace('_',' ')}"

  # Handels activation count
  robot.respond /activations ?(.*)/i, (msg) ->

    timeframe = (if msg.match[1] then msg.match[1] else "today").toLowerCase()
    countActivations = create_activations_query(timeframe)

    console.log countActivations
    keenClient.run countActivations, (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        msg.send "We had #{res.result} activations #{timeframe.replace('_',' ')}"

  # Handels activation count
  robot.respond /conversions ?(\w*) ?(\w*)/i, (msg) ->

    timeframe = (if msg.match[1] then msg.match[1] else "today").toLowerCase()
    country = if msg.match[2] then msg.match[2]

    human_timefram = timeframe.replace("_", " ")

    countActivations = create_activations_query(timeframe)
    countSignUps = create_signup_query(timeframe)

    if country
      country_try_out_condition = {
        "operator": "eq",
        "property_name": "country",
        "property_value": country
      }

      country_deal_condition =  {
        "operator": "contains",
        "property_name": "deal.tags",
        "property_value": ".#{country}"
      }
      countActivations.params.filters.push(country_deal_condition)
      countSignUps.params.filters = [country_try_out_condition]

    keenClient.run [countSignUps, countActivations], (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        signups = res[0].result
        activation = res[1].result
        if signups > 0
          conversion_rate = Math.round((activation / signups) * 100)
          message = "
          #{human_timefram} we had #{signups} sign-ups and
 #{activation} activations,
 giving us an conversion rate of #{conversion_rate}%"
          if country
            message += " in #{country}"
          msg.send message
        else
          msg.send "Sorry, we didn't have a single sign-up #{human_timefram}"
