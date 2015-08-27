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

  class Douche
    constructor: (name, points) ->
      @name = name ? ""
      @points = points ? 0
      @achivements = []

    loadFromRawData: (rawDouche) ->
      {@name, @points, @achivements} = rawDouche
      return

    addPoints: (new_points) ->
      @points += new_points
      return

    removePoints: (new_points) ->
      @points -= new_points
      return

    unlockAchivement: (achivement) ->
      @achivements.push(achivement)

  class HighscoreBoard
    constructor: (@brain, @boardName) ->
      @board = {}
      @brain.get(@boardName)?.map (key,value) ->
        @board[key] = new Douche().loadFromRawData(value)

    addUser: (doucheName, points) ->
      @board[doucheName] = new Douche(doucheName, points)

    findUser: (doucheName) ->
      return @board[doucheName]

    awardPoints: (doucheName, points) ->
      @_changePoints(doucheName, points)
      return

    removePoints: (doucheName, points) ->
      availablePoints = @getScoreForDouche(doucheName)
      if availablePoints > points
        @_changePoints(doucheName, -points)
      else
        @_changePoints(doucheName, -availablePoints)
      @_save()
      return

    getHighScore: (numberOfIntems) ->
      nbr = numberOfIntems ? 3
      return _.chain(@board)
      .values()
      .sortByOrder('points', 'desc')
      .splice(0, numberOfIntems)
      .value()

    getScoreForDouche: (doucheName) ->
      @findUser(doucheName)?.points

    _save: () ->
      @brain.set(@boardName, @board)

    _changePoints: (doucheName, points) ->
      douche = @findUser(doucheName)
      if douche
        douche.addPoints(points)
      else
        @addUser(doucheName, points)
      @_save()
      return

  highscoreBoard = new HighscoreBoard(robot.brain, 'douchepoints')
  awardPoints = (msg, douche, new_points, sender) ->
    if douche == "#{@sender}"
      msg.send "Cudos for trying to give yourself douche points!
 Not even Kevin Federline would have tried that! Minus 50dp for you!"
      highscoreBoard.removePoints(douche, 50)
      return
    highscoreBoard.awardPoints(douche, new_points)
    msg.send "Nice! #{douche} just recived #{new_points}dp and now holds
 a total of #{highscoreBoard.getScoreForDouche(douche)}"


  messagePattern1 = ///                   #begin of line
    ([0-9]{1,4})                          #group 1: 1-4 numbers, i.e. d-points
    \s?                                   #optional whitespace
    (?:dp|douche points?|douchepoints?)   #dont capture. ending s optional
    (?:\s|\still\s|\sto\s)                #dont capture. ws, ws+till, ws+to
    (@[a-ö_-]+)                           #@username, letters and _-
    ///i                                  #end of line and ignore case

  # Handels sign-ups
  robot.hear messagePattern1, (msg) ->
    new_points = parseInt(msg.match[1])
    douche = msg.match[2].toLowerCase()
    sender = msg.message.user.name.toLowerCase()
    awardPoints(msg, douche, new_points, sender)

  robot.hear /(@[a-ö_-]+):?\s([0-9]{1,4})\s?(?:dp|douche points?|douchepoints?)/i, (msg) ->
    new_points = parseInt(msg.match[2])
    douche = msg.match[1].toLowerCase()
    sender = msg.message.user.name.toLowerCase()
    awardPoints(msg, douche, new_points, sender)

  robot.respond /(douche highscore|what's the current douche off)\s?([0-9])?/i, (msg) ->
    nbrOfItems = parseInt(msg.match[2] ? 3)
    msg.send _.map highscoreBoard.getHighScore(nbrOfItems), (douche, index) ->
      return "#{index+1}. #{douche.name}: #{douche.points}dp"
    .join("\n")

  robot.respond /(?:give|show)?(?:me)?(?:douche points|dp|dps|)\s(?:for)?(@[a-ö_-]+)/i, (msg) ->
    douche = msg.match[1]
    points = highscoreBoard.getScoreForDouche(douche)
    msg.send "#{douche} has currently #{points}dp"
