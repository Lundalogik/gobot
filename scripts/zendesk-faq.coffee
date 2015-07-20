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
      {@title, @body} = rawArticle

    serialize: () ->
      return "#{@title} \n #{@body}..."


  robot.respond /faq ?(.*)/i, (msg) ->
    console.log "Running FAQ"
    url = "#{zendeskURL}#{search_url}#{encodeURIComponent(msg)}"
    console.log url
    robot.http(url)
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      console.log "HTTP request done"
      if err
        msg.send "Something went wrong: #{err}"
        return null

      console.log "HTTP answer", body
      data = JSON.parse body
      articlesArray = (new FAQArticle(article).serialize() for article in data if article.result_type == "article")

      msg.send articlesArray.toString()
