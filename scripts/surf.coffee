# Description:
#   Get the surf report for lat/long coordinates or a predefined region (Carrillo, Samara, Nosara, and Camaronal)
#
# Commands:
#   hubot surf <city:cityname>

api_key = process.env.HUBOT_WORLDWEATHERONLINE_API_KEY or 'fc38fd396afef8f31b877b23d33b54f20e92f600'
google_api = 'http://maps.googleapis.com/maps/api/staticmap?center='

wind_directions =
    SW: 'Onshore'
    NW: 'Onshore'
    W: 'Onshore'
    N: 'Sideshore'
    S: 'Sideshore'
    NE: 'Offshore'
    SE: 'Offshore'
    E: 'Offshore'

coordinates =
    carrillo: '9.8663679,-85.4909363'
    samara: '9.8766711,-85.5249146'
    nosara: '9.971286,-85.6855052'
    camoranal: '9.8551676,-85.4448617'

roundNumber = (number, precision) ->
  precision = Math.abs(parseInt(precision)) or 0
  multiplier = Math.pow(10, precision)
  Math.round(number * multiplier) / multiplier

realTime = (time) ->
  if time > 12
    return "#{time - 12}" + "PM"

  else
    return "#{time}" + "AM"


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
        msg.send "*SURF REPORT FOR #{date}*"
        msg.send ""

        for hour in hourly
          reportTime = hour.time / 100

          if reportTime > (currentTime - 2)

            waveHeight = hour.swellHeight_m * 3.28084
            waveHeightRounded = roundNumber(waveHeight, 2)
            swellPeriod = hour.swellPeriod_secs
            windDir = hour.winddir16Point
            windspeedMiles = hour.windspeedMiles
            rt = realTime(reportTime)

            msg.send "*Surf Report:* #{rt}"
            msg.send "*Wave Height:* #{waveHeightRounded}ft at #{swellPeriod} seconds"
            msg.send "*Wind:* #{windspeedMiles}mph, #{wind_directions[windDir]}"
            msg.send ""

      catch error
        msg.send "Some bad shit happened."
