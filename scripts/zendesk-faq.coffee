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
    constructor(rawArticle) ->
      {@title, @body} = rawArticle

    serialize: () ->
      return "#{@title} \n #{@body}..."
  # Handels goals for Sign-ups
  robot.respond /faq ?(.*)/i, (msg) ->
    robot.http('#{zendeskURL}#{search_url}#{encodeURIComponent(msg)}')
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      if err
        res.send "Something went wrong: #{err}"

      data = JSON.parse body
      articlesArray = (new FAQArticle(article).serialize() for article in data if article.result_type == "article")

      res.send articlesArray.toString()
