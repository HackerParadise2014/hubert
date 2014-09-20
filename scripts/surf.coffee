# Description:
#   Get the surf report for lat/long coordinates or a predefined region (Carrillo, Samara, Nosara, and Camaronal)
#
# Commands:
#   hubot surf <city:cityname>

api_key = process.env.HUBOT_WORLDWEATHERONLINE_API_KEY or 'fc38fd396afef8f31b877b23d33b54f20e92f600'
google_api = 'http://maps.googleapis.com/maps/api/staticmap?center='

coordinates =
    carrillo: '9.87605,-85.493'
    samara: '10.25,-85.416'
    nosara: '9.9833,-85.649'
    camoranal: '9.7579,-84.6214'

roundNumber = (number, precision) ->
  precision = Math.abs(parseInt(precision)) or 0
  multiplier = Math.pow(10, precision)
  Math.round(number * multiplier) / multiplier

module.exports = (robot) ->
  robot.respond /surf (\w+)/i, (msg) ->
    city_name = msg.match[1].toLowerCase()
    coords = switch(city_name)
             when 'carrillo' then coordinates.carrillo
             when 'samara' then coordinates.samara
             when 'nosara' then coordinates.nosara
             when 'camaronal' then coordinates.camaronal
             else coordinates.carrillo

    api_url = "http://api.worldweatheronline.com/free/v1/marine.ashx?q=#{coords}&format=json&fx=yes&includelocation=yes&lang=en&key=#{api_key}"
    msg.http(api_url).get() (err, res, body) ->
      try
        json = JSON.parse(body)
        weather = json.data.weather[0]
        hourly = weather.hourly
        date = weather.date
        currentTime = new Date().getHours()
        map_url = "#{google_api}" + "#{coords}" +
                  "&zoom=15&size=600x600&maptype=satellite" +
                  "&markers=color:blue%7Clabel:S%7C" +
                  "#{coords}"

        msg.send map_url
        msg.send ""
        msg.send "########################################"
        msg.send "#### Surf Report for #{date}  #####"
        msg.send "########################################"

        for hour in hourly
          reportTime = hour.time / 100

          if reportTime > (currentTime - 2)
            waveHeight = hour.swellHeight_m * 3.28084
            waveHeightRounded = roundNumber(waveHeight, 2)
            swellPeriod = hour.swellPeriod_secs
            windDir = hour.winddir16Point
            windspeedMiles = hour.windspeedMiles

            msg.send ""
            msg.send "Surf report for #{reportTime}"
            msg.send "Wave height #{waveHeightRounded} in feet at #{swellPeriod} seconds"
            msg.send "With wind coming from #{windDir} at #{windspeedMiles} mph"
            msg.send ""
            msg.send "----------------------------------------"

      catch error
        msg.send "Some bad shit happened."
