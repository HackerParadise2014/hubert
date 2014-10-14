# Description:
#   Utility commands surrounding Hubot uptime.
#
# Commands:
# 

Url   = require "url"
Redis = require "redis"
UUID  = require "node-uuid"

module.exports = (robot) ->
  info   = Url.parse process.env.REDISTOGO_URL or process.env.REDISCLOUD_URL or process.env.BOXEN_REDIS_URL or process.env.REDIS_URL or 'redis://localhost:6379', true
  client = Redis.createClient(info.port, info.hostname)

  robot.hear /cc scheduler/i, (msg) -> 
    event_id = String(UUID.v4())[0..7]
    timestamp = new Date().getTime()
    msg.message.event_id = event_id
    client.set "scheduler_#{timestamp}_#{event_id}:messages", JSON.stringify(msg.message)
    event_title = msg.message.text.replace(msg.match[0], '')

    msg.send("To opt in for #{event_title}, respond with 'scheduler yes #{event_id}'.")


  robot.hear /scheduler help/i, (msg) ->
    reply_str = "Available commands: \n" +
      "<event_title> cc scheduler: Create new event \n" +
      "scheduler yes <event_id> <message>: Add yourself to participants list. Add optional <message> for the event creator. \n" +
      "scheduler no <event_id>: Remove yourself from participants list. \n" +
      "scheduler status <event_id>: List event participants\n" +
      "scheduler roundup <event_id>: @mention event participants\n" + 
      "scheduler list <count>: List last <count> events. Defaults to 5.\n"

    msg.send(reply_str)

  robot.hear /scheduler yes ([\w\d]{8})/i, (msg) ->
    event_id = msg.match[1]
    client.keys "scheduler_*_#{event_id}:messages", (err, keys) ->
      if err 
        throw err

      if keys.length == 1
        event_key = keys[0].replace('messages', 'responses')
        client.get event_key, (err, replies) ->
          if err
            throw err
          replies ||= "{}"

          robot.logger.info replies

          parsed = JSON.parse(replies)
          parsed[msg.message.user.name] = msg.message.text.replace(msg.match[0], '')
          client.set event_key, JSON.stringify(parsed)

          robot.logger.info JSON.stringify(parsed)
      else if keys.length == 0
        msg.send("Invalid event id.")
      else 
        msg.send("The universe is not random.")


  robot.hear /scheduler no ([\w\d]{8})/i, (msg) ->
    event_id = msg.match[1]
    client.keys "scheduler_*_#{event_id}:messages", (err, keys) ->
      if err 
        throw err

      if keys.length == 1
        event_key = keys[0].replace('messages', 'responses')
        client.get event_key, (err, replies) ->
          if err
            throw err
          replies ||= "{}"

          parsed = JSON.parse(replies)
          unless parsed[msg.message.user.name] == undefined
            delete parsed[msg.message.user.name]
            client.set event_key, JSON.stringify(parsed)
      else if keys.length == 0
        msg.send("Invalid event id.")
      else 
        msg.send("The universe is not random.")


  robot.hear /scheduler list ?(\d+)?/i, (msg) ->
    count = Number(msg.match[1]) || 5

    if count == 0
      msg.send("You don't get zero events. Fuck you.")

    client.keys "scheduler_*:messages", (err, keys) ->
      keys = keys.sort().reverse()[0..(count - 1)]
      robot.logger.info(keys)
      client.mget keys, (err, values) ->
        if err
          throw err 

        list_str = "Last #{count} events:\n"
        for value in values
          value = JSON.parse(value)
          text = value.text.replace('cc scheduler', '')
          list_str += "Event '#{text}' has ID: #{value.event_id}. Use #{value.event_id} to list participants or opt in/out. \n"
        
        msg.send(list_str)


  robot.hear /scheduler status ([\w\d]{8})/i, (msg) ->
    event_id = msg.match[1]
    client.keys "scheduler_*_#{event_id}:messages", (err, keys) ->
      if err 
        throw err

      if keys.length == 1
        event_key = keys[0].replace('messages', 'responses')
        robot.logger.info(event_key)
        client.get event_key, (err, replies) ->
          if not replies
            msg.send("No responses found for #{event_id}.")
          if replies 
            replies = JSON.parse(replies)
            replies_count = Object.keys(replies).length
            replies_str = "#{replies_count} replies\n"
            for username, reply of replies 
              replies_str += "#{username}: #{reply}\n"

            msg.send(replies_str)
      else if keys.length == 0
        msg.send("Invalid event id.")
      else 
        msg.send("The universe is not random.")


  robot.hear /scheduler roundup ([\w\d]{8})/i, (msg) ->
    event_id = msg.match[1]
    client.keys "scheduler_*_#{event_id}:messages", (err, keys) ->
      if err 
        throw err

      if keys.length == 1
        event_key = keys[0].replace('messages', 'responses')
        client.get event_key, (err, replies) ->
          if not replies
            msg.send("no.")

          replies = JSON.parse(replies)
          replies_str = ""
          for username, reply of replies 
            replies_str += "@#{username} "

          msg.send(replies_str + "let's go!")
      else if keys.length == 0
        msg.send("Invalid event id.")
      else 
        msg.send("The universe is not random.")

  if info.auth
    client.auth info.auth.split(":")[1], (err) ->
      if err
        robot.logger.error "Failed to authenticate to Redis"
      else
        robot.logger.info "Successfully authenticated to Redis"

  client.on "error", (err) ->
    robot.logger.error err

  client.on "connect", ->
    robot.logger.debug "Successfully connected to Redis"







# DIRECT MESSAGE WEBHOOK CODE

# webhook_url = 'https://hackerparadise2014.slack.com/services/hooks/incoming-webhook?token=MJhXhakAnBMLSq781YPgOeEo'
# webhook_params = {
#   "channel": "#" + msg.message.room, 
#   "username": "Hacker Paradise Scheduler", 
#   "text": "To opt in for #{event_title}, respond with 'scheduler yes #{event_id}'.", 
#   "icon_emoji": ":eggplant:"}

# msg.http(webhook_url).post(JSON.stringify(webhook_params)) (err, res, body) ->
#   if err
#     throw err 
#   else if res 
#     robot.logger.info body 
