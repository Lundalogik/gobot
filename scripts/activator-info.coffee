# Description:
#   Hunts down what a activated signup has done before
#
# Dependencies:
#   "keen-js": "^3.2.1"
#
# Commands:
#   listens to the standard activation phrase:
#   "Signup from [email] [???] just activated"
#
#   also reads "gobot backgrack [email]"
#   or "gobot backtrack signup [email] this_700_days"
#   or similar
#
# Author:
#   jse

Keen = require 'keen-js'


module.exports = (robot) ->

#live:
  keenClient = new Keen(
    projectId: process.env.KEEN_PROJECT_ID
    readKey:  process.env.KEEN_READ_KEY
    masterKey:  process.env.KEEN_MASTER_KEY
  )

  #standard variables
  emailErrorMsg = "How should i know where that dude / dudette came from? \n
  Read up in keen, slacker! Or ask me again, NICELY."

  timeFrameErrorMsg = "You used a time frame I can't understand,
  please use a relative time frame from
  https://keen.io/docs/data-analysis/timeframe/ \n
  Examples: Today, Yesterday, last_2_months, this_week"

  defaultTimeframeSignups = "this_14_days"

  defalutTimeframePageviews = "this_30_days"

  defaultTimeframeBacktrack = "this_365_days"


  #handles functions
  getActivatorHistory = (msg, email, timeframeSignups, timeframePageviews) ->
    permanentTracker = []
    messageBuffer = ""

    extractSignups = new Keen.Query "extraction",
      eventCollection: "Marketsite-TryOutSubmited"
      filters: [{"operator":"eq","property_name":"email","property_value": email}]
      timeframe: timeframeSignups
      timezone: "Europe/Stockholm"

    keenClient.run extractSignups, (err, res) ->
      if err
        console.log 'Keen error:', err
        msg.send "error: #{err}"
        msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
      else
        if res.result[0]
          messageBuffer += "*Sigup(s)* in `#{timeframeSignups}` for #{email}:"
          for result in res.result
            permanentTracker.push result.permanent_tracker
            messageBuffer += "\n" + "#{result.keen.timestamp.replace('T',' ').split('.')[0]} - #{result.url.domain}#{result.url.path}"

          msg.send messageBuffer
          messageBuffer = ""
          messageBuffer = "*Visit(s)* in `#{timeframePageviews}` for #{email}:"

          extractPageviews = new Keen.Query "extraction",
            eventCollection: "Marketsite-Pageview"
            filters: [{"operator":"in","property_name":"permanent_tracker","property_value": permanentTracker}]
            timeframe: timeframePageviews
            timezone: "Europe/Stockholm"

          keenClient.run extractPageviews, (err, res) ->
            if err
              console.log 'Keen error:', err
              msg.send "error: #{err}"
              msg.send timeFrameErrorMsg if err.code == "TimeframeDefinitionError"
            else
              for result in res.result
                messageBuffer += "\n" + "#{result.keen.timestamp.replace('T',' ').split('.')[0]} - #{result.url.domain}#{result.url.path}"
              messageBuffer += "\n" + "\n" + "Visits was registered for *#{permanentTracker.length}* devices / cookies"
              msg.send messageBuffer
        else
          msg.send emailErrorMsg


  #handles message patterns
  messagePatternActivation = ///                #begin of line
    (?:Signup.from.)                            #dont capture start of sentence "." is space
    \b(                                         #start of wordblock, group 1
    [a-z0-9._%+#-_~!$&'()*,;=:"<>[\\\]]+        #any character allowed in email adress
    @                                           #the sign @
    [a-z0-9._%+#-_~!$&'()*,;=:"<>[\\\]]+        #any character allowed in email adress, including . and domain
    )\b                                         #end of wordblock and group 1
    (?:.*)                                      #any characters / spaces. dont capture
    (?:a.new.deal)                              #sentence should also contain "a new deal"
    (?:.*)                                      #any characters / spaces. dont capture
    ///i                                        #end of line and ignore case

  messagePatternBacktrack = ///                 #begin of line
    (?:backtrack\s)                             #dont capture backtrack, but must have this
    (?:activator\s)?                            #optional, dont capture
    (?:sign[\s-]?up\s)?                         #optional, dont capture
    (?:activation\s)?                           #optional, dont capture
    (?:e[\s-]?mail\s)?                          #optional, dont capture
    \b(                                         #start of wordblock, group 1
    [a-z0-9._%+#-_~!$&'()*,;=:"<>[\\\]]+        #any character allowed in email adress
    @                                           #the sign @
    [a-z0-9._%+#-_~!$&'()*,;=:"<>[\\\]]+        #any character allowed in email adress, including . and domain
    )\b                                         #end of wordblock and group 1
    \s?(.*)?                                     #optional last word, group 2, preceded by whitespace
    ///i

  messagePatternStalk = ///                     #begin of line
    (?:stalk\s)                                 #dont capture backtrack, but must have this
    (?:activator\s)?                            #optional, dont capture
    (?:sign[\s-]?up\s)?                         #optional, dont capture
    (?:activation\s)?                           #optional, dont capture
    (?:e[\s-]?mail\s)?                          #optional, dont capture
    \b(                                         #start of wordblock, group 1
    [a-z0-9._%+#-_~!$&'()*,;=:"<>[\\\]]+        #any character allowed in email adress
    @                                           #the sign @
    [a-z0-9._%+#-_~!$&'()*,;=:"<>[\\\]]+        #any character allowed in email adress, including . and domain
    )\b                                         #end of wordblock and group 1
    \s?(.*)?                                     #optional last word, group 2, preceded by whitespace
    ///i


  #Mr. robot

  #How the code should look. not working since hear doent hear bots.
  # robot.hear messagePatternActivation, (msg) ->
  #   activatorEmail = msg.match[1].toLowerCase()     #msg.match[0] is entire message
  #
  #   getActivatorHistory(msg, activatorEmail, defaultTimeframeSignups, defalutTimeframePageviews)

  #Special hack to hear bots:

  robot.catchAll (msg) ->
    matches = msg.message.text.match(messagePatternActivation)
    if matches != null && matches.length > 1
      activatorEmail = matches[1].toLowerCase()     #msg.match[0] is entire message
      getActivatorHistory(msg, activatorEmail, defaultTimeframeSignups, defalutTimeframePageviews)
    msg.finish()


  robot.respond messagePatternBacktrack, (msg) ->
    timeframeSignups = timeframePageviews = if msg.match[2] then msg.match[2].toLowerCase() else defaultTimeframeBacktrack
    activatorEmail = msg.match[1].toLowerCase()

    getActivatorHistory(msg, activatorEmail, timeframeSignups, timeframePageviews)

  robot.respond messagePatternStalk, (msg) ->
    timeframeSignups = timeframePageviews = if msg.match[2] then msg.match[2].toLowerCase() else defaultTimeframeBacktrack
    activatorEmail = msg.match[1].toLowerCase()

    getActivatorHistory(msg, activatorEmail, timeframeSignups, timeframePageviews)
