# Description:
#   Keeps track of our the current douche points
#
# Dependencies:

#
# Commands:
#   hubot sign-ups <time frame> - shows the number of sign-ups for time frame. Avialable time frames can be found here: https://keen.io/docs/data-analysis/timeframe/ Examples: Today, Yesterday, last_2_months, this_week
#
# Author:
#   fpe

_ = require 'lodash'

module.exports = (robot) ->
  lmgtfyUrl = "http://bit.ly/2fyESjf"
  gotest = "<" + lmgtfyUrl + "|goatse>"

  gobot_message = "Did you mean " + gotest + "?"

  messagePattern1 = ///                   #begin of line
    (?:gotests?|go-tests?)                          #dont capture. ending s optional
    ///i                                  #end of line and ignore case

  # Handels sign-ups
  robot.hear messagePattern1, (msg) ->
    msg.send gobot_message