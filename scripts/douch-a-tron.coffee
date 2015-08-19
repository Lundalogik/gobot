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
module.exports = (robot) ->
  # Handels sign-ups
  robot.hear /([0-9]{1,4})\s?(?:dp|douche points?|douchepoints?)(?:\s|\still\s|\sto\s)(@[a-ö]+)/i, (msg) ->
    new_points = parseInt(msg.match[1])
    console.log msg.match
    douche = msg.match[2].toLowerCase()
    sender = msg.message.user.name.toLowerCase()
    douchepoints = {}
    douchepoints ?= robot.brain.get('douchepoints')
    douchepoints[douche] ?= 0

    if douche == "#{@sender}"
      douchepoints[douche] -= 50
      robot.brain.set 'douchepoints', douchepoints
      msg.send "Cudos for trying to give yourself douche points!
Not even Kevin Federline would have tried that! Minus 50dp for you!"

      return

    douchepoints[douche] += new_points
    robot.brain.set 'douchepoints', douchepoints
    msg.send "Nice! #{douche} just recived #{new_points}dp and now holds
a total of #{douchepoints[douche]}"
