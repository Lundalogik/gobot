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
  # Handels goals for Sign-ups
  robot.respond /faq ?(.*)/i, (msg) ->
    console.log "Running FAQ"
    robot.http('#{zendeskURL}#{search_url}#{encodeURIComponent(msg)}')
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      console.log "HTTP request done"
      if err
        msg.send "Something went wrong: #{err}"

      console.log "HTTP answer", body
      data = JSON.parse body
      articlesArray = (new FAQArticle(article).serialize() for article in data if article.result_type == "article")

      msg.send articlesArray.toString()
