# WeatherNow

WeatherNow is an iPhone weather app. Home, Details, Explore, and Forecast use live data from [Open-Meteo](https://open-meteo.com/). Nothing on screen is a fixed temperature.

The interface is frosted glass on a glowing sky. It follows the phone’s appearance, and the sun/moon button in the header switches between light and dark.

## Run it

1. Open `WeatherApp.xcodeproj` in Xcode 16.
2. Pick an iPhone simulator and press Run.
3. Allow location when asked.
4. In the simulator, set a position with **Features → Location → Apple** or a custom latitude and longitude. Without a simulated location, the first screen asks you to search instead.

Pull down on Home, Details, or Forecast to refresh. Explore searches after three letters. The bookmark keeps a city on this phone. The outlined city is the one shown on the other tabs.

## API

No API key. Non-commercial use of Open-Meteo is free. Weather figures are credited on screen as “Weather data by Open-Meteo” ([CC BY 4.0](https://open-meteo.com/)).

The app calls the standard forecast endpoint, not `models=dwd_icon_seamless`. The default best-match model includes UV index and works outside Europe. DWD ICON does not publish `uv_index`.

| Screen | Endpoint | What it asks for |
| --- | --- | --- |
| Home | `https://api.open-meteo.com/v1/forecast` | `current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day` and `daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max` with `timezone=auto` and `forecast_days=7` |
| Details | same forecast call | `hourly=temperature_2m,weather_code,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,precipitation_probability,uv_index,is_day` and `forecast_hours=24` |
| Explore search | `https://geocoding-api.open-meteo.com/v1/search` | `name`, `count=8`, `language=en` |
| Explore temperatures | forecast, many coordinates | `current=temperature_2m,weather_code,is_day`. Latitudes and longitudes are comma-separated in one request |
| Forecast tab | same forecast call as Home | seven `daily` rows, plus the saved-city current call above |

`timezone=auto` makes sunrise, sunset, and day names local to the city. Temperature is Celsius and wind is km/h, which are the API defaults. The wind unit label is read from `current_units`, not typed in the view.

Icons come from the WMO `weather_code`. `is_day` picks the night symbol. The app does not ask for visibility.

## Code

On launch, Home asks Core Location for the device position and then loads that forecast. A city picked in Explore is kept until the next cold start.

```swift
func appBecameActive() {
    if !didStart {
        didStart = true
        selectedTab = .home
        Task { await loadSuggestions() }
        Task { await loadDeviceForecast(keepPreviousOnFailure: false) }
        return
    }
    guard usingDeviceLocation else { return }
    Task { await loadDeviceForecast(keepPreviousOnFailure: true) }
}
```

One forecast call fills Home, Details, and the seven-day list. `models` is left off so the default best-match model is used.

```swift
func forecast(latitude: Double, longitude: Double) async throws -> Forecast {
    let url = try makeURL(
        base: "https://api.open-meteo.com/v1/forecast",
        items: [
            URLQueryItem(name: "latitude", value: Self.coordinates([latitude])),
            URLQueryItem(name: "longitude", value: Self.coordinates([longitude])),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "forecast_hours", value: "24"),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day"
            ),
            URLQueryItem(
                name: "hourly",
                value: "temperature_2m,weather_code,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,precipitation_probability,uv_index,is_day"
            ),
            URLQueryItem(
                name: "daily",
                value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max"
            )
        ]
    )
    let data = try await fetch(url)
    return try JSONDecoder().decode(Forecast.self, from: data)
}
```

City search uses the geocoding API. Explore and Saved then ask for current conditions for every coordinate in one request.

```swift
func search(name: String) async throws -> [Place] {
    let url = try makeURL(
        base: "https://geocoding-api.open-meteo.com/v1/search",
        items: [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "count", value: "8"),
            URLQueryItem(name: "language", value: "en")
        ]
    )
    let data = try await fetch(url)
    return try JSONDecoder().decode(GeocodingResponse.self, from: data).results ?? []
}
```

```swift
URLQueryItem(name: "latitude", value: Self.coordinates(places.map(\.latitude))),
URLQueryItem(name: "longitude", value: Self.coordinates(places.map(\.longitude))),
URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day")
```

A single place comes back as one JSON object. Several places come back as an array. Coordinates are formatted with a dot decimal so a locale comma is never sent.

Your position uses Core Location. The city name uses Apple’s reverse geocoder, then the Open-Meteo search result when that city is within 40 km, so the forecast stays on the real coordinates when the match is far away. Saved cities are stored on the device. Open-Meteo has no accounts.

## Layout

- `WeatherClient` builds the forecast and geocoding requests.
- `LocationProvider` asks for When-In-Use location.
- `SavedCityStore` writes bookmarks to UserDefaults.
- `WeatherStore` is the screen state: the selected city, the forecast, search, and errors.
- Views are SwiftUI. `ForecastGate` shows the loading card or the offline / failed message until a forecast exists.

Offline and failed requests stay on a retry card. If location is off, Explore is still available.
