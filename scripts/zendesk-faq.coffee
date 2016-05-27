# Description:
#   Searches a zendesk FAQ and returns
#
# Dependencies:
#
#
# Commands:
#   /faq <search query>
#
# Author:
#   fpe


module.exports = (robot) ->

  zendeskURL = 'https://faq.lundalogik.com'
  search_url = '/api/v2/help_center/articles/search.json?query='
  category_filter = '&category=200908849&locale=en-gb'

  class FAQArticle
    constructor: (rawArticle) ->
      {@title, @body, @html_url} = rawArticle

    serialize: () ->
      return "#{@title} <#{@html_url}|read more...>"

    toSlackAttachment: () ->
      htmlFreeBody = @body.replace(/(<([^>]+)>)/ig, "")
      htmlFreeBody = htmlFreeBody.replace("&nbsp;", "\n")
      return  {title: @title, text: htmlFreeBody, title_link:@html_url}

  respondToFAQQuery = (query, channel) ->
    message = {}
    message.room = channel

    sendMsg = (msg) ->
      robot.messageRoom channel, msg

    if not query
      sendMsg "You didn't provide a search query!"
      return
    robot.http("#{zendeskURL}#{search_url}#{encodeURIComponent(query)}#{category_filter}")
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      if err
        msg.send "Something went horribly wrong: #{err}"
        return

      data = JSON.parse body
      if not data.results.length
        sendMsg "Couldn't find anything in the FAQ regarding '#{query}'"
        return
      if data.count > data.per_page
        sendMsg "I found #{data.count} articles, showing you the #{data.per_page} best hits"

      attachments = (new FAQArticle(article).toSlackAttachment() for article in data.results)

      robot.emit 'slack.attachment',
        message: message
        content:
          attachments: attachments

  robot.respond /faq ?(.*)/i, (msg) ->
    query = msg.match[1]
    channel = msg.message.room
    respondToFAQQuery(query, channel)

  robot.router.post '/hubot/faq', (req, res) ->

    console.log req.body.channel_name
    if not req.body?
      res.send 500
      return

    data = req.body

    token = data.token
    channel = data.channel_name
    query = data.text

    #if not token == TOKEN
    #  return

    res.send "Telling Gobot to search the faq!"
    respondToFAQQuery(query, channel)
