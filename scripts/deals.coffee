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

Keen  = require 'keen-js'
_     = require 'lodash'

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

  formatMoney = (number) ->
    return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ") + "kr"

  class Deal
    constructor: (@coworker, @value) ->

  # Handels sign-ups
  robot.respond /deals ?(.*)/i, (msg) ->

    timeframe = if msg.match[1] then msg.match[1] else "today"
    goDeals = new Keen.Query "extraction",
      eventCollection: "Sales-DealWon"
      timeframe: timeframe
      timezone: "Europe/Stockholm"

    proDeals = new Keen.Query "extraction",
      eventCollection: "Won deals"
      timeframe: timeframe
      timezone: "Europe/Stockholm"

    keenClient.run [goDeals, proDeals], (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else

        # remove deals from non Go-team
        goWonDealEvents = _(res[0].result)
        .remove (dealEvent) ->
          return dealEvent.deal.responsible.firstName?
        .map (dealEvent) ->
          name ="#{dealEvent.deal.responsible.firstName} #{dealEvent.deal.responsible.lastName}"
          return new Deal(name, dealEvent.deal.value)
        .value()

        # map pro deals
        proWonDeals = _.map res[1].result, (dealEvent) ->
          return new Deal(dealEvent.responsiblesales, dealEvent.totalvalue)

        goDealEvents = goWonDealEvents.concat proWonDeals
        # Money
        highscore = _(goDealEvents)
        .groupBy (dealEvent) ->
          return dealEvent.coworker
        .mapValues (deals) ->
          return amount = _.sum deals, (dealEvent) ->
            return dealEvent.value
        .pairs() #turns object into a array {a:b, c:d} => [[a,b],[b,c]]
        .sortByOrder (pair) ->
          return pair[1]
        .map (pair) ->
          listing={}
          listing[pair[0]] = pair[1]
          return listing
        .value()

        totalValue = _.sum goDealEvents, (dealEvent) ->
          return dealEvent.value
        # Number of deals
        nbrOfDeals = goDealEvents.length
        nbrOfDealsPerSalesRep = _(goDealEvents)
        .groupBy (dealEvent) ->
          return dealEvent.coworker
        .mapValues (deals) ->
          return amount = deals.length
        .value()


        msg.send "We have won #{nbrOfDeals} deals during #{timeframe.replace('_',' ')} with a total value of *#{formatMoney totalValue}*"
        i = 1
        _.forEachRight highscore, (listing) ->
          coworker = _.keys(listing)[0]
          totalSales = _.values(listing)[0]
          nbrOfDeals = nbrOfDealsPerSalesRep[coworker]
          averageValue = Math.round(totalSales/nbrOfDeals)
          msg.send "#{i}. #{coworker}: *#{formatMoney totalSales}* _(#{nbrOfDeals} deals, avg: #{formatMoney averageValue})_"
          i++
