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

  zendeskURL = 'https://lime-go.zendesk.com'
  search_url = '/api/v2/help_center/articles/search.json?query='

  class FAQArticle
    constructor: (rawArticle) ->
      {@title, @body, @url} = rawArticle

    serialize: () ->
      return "#{@title} <read more | #{@url}>"


  robot.respond /faq ?(.*)/i, (msg) ->

    query = msg.match[1]
    if not query
      msg.send "You didn't provide a search query!"
      return
    robot.http("#{zendeskURL}#{search_url}#{encodeURIComponent(query)}")
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      if err
        msg.send "Something went horribly wrong: #{err}"
        return
      data = JSON.parse body
      if not data.results.length
        msg.send "Couldn't find anything in the FAQ regarding '#{query}'"
        return
      console.log data
      articlesArray = (new FAQArticle(article).serialize() for article in data.results)

      msg.send articlesArray.toString()
