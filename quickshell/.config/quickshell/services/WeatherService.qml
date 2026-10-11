pragma Singleton

import QtQuick
import Quickshell.Io

// WeatherService — single source of truth for the bar's weather chip and the
// Date page's weather card. Uses Open-Meteo (no API key) and maps WMO codes to
// Nerd Font glyphs so every view renders exactly the same icon.
Item {
    id: root
    visible: false

    // Lima, Peru
    readonly property real latitude: -12.0464
    readonly property real longitude: -77.0428

    readonly property string endpoint: "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + root.latitude
        + "&longitude=" + root.longitude
        + "&current=temperature_2m,weather_code"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
        + "&timezone=auto&forecast_days=5"

    // Reverse geocoding without an API key, so we can show the real city name.
    readonly property string geoEndpoint: "https://api.bigdatacloud.net/data/reverse-geocode-client"
        + "?latitude=" + root.latitude
        + "&longitude=" + root.longitude
        + "&localityLanguage=en"

    property string glyph: ""
    property string temperature: ""
    property string city: ""
    property string country: ""
    property var forecast: []   // [{ weekday, glyph, max, min }]

    // "Ciudad, País" (o solo lo que haya).
    readonly property string location: {
        if (root.city === "")
            return root.country
        if (root.country === "")
            return root.city
        return root.city + ", " + root.country
    }

    readonly property string summary: {
        if (root.glyph === "" && root.temperature === "")
            return ""
        if (root.temperature === "")
            return root.glyph
        if (root.glyph === "")
            return root.temperature
        return root.glyph + " " + root.temperature
    }

    // WMO weather codes -> Nerd Font "weather-*" glyphs (verified in
    // JetBrainsMono Nerd Font: e30d/e302/e312/e33d/e313/e318/e319/e31a/e315).
    function glyphFor(code) {
        if (code === 0 || code === 1) return "\ue30d"              // clear / mainly clear
        if (code === 2) return "\ue302"                            // partly cloudy
        if (code === 3) return "\ue312"                            // overcast
        if (code === 45 || code === 48) return "\ue313"            // fog
        if (code >= 51 && code <= 57) return "\ue318"              // drizzle
        if (code === 61 || code === 63 || code === 66 || code === 67) return "\ue318" // rain
        if (code === 65) return "\ue319"                           // heavy rain
        if (code === 71 || code === 73 || code === 75 || code === 77) return "\ue31a" // snow
        if (code === 80 || code === 81 || code === 82) return "\ue319" // rain showers
        if (code === 85 || code === 86) return "\ue31a"            // snow showers
        if (code === 95 || code === 96 || code === 99) return "\ue315" // thunderstorm
        return "\ue302"
    }

    function formatTemperature(t) {
        if (t === undefined || t === null || isNaN(t))
            return ""
        return Math.round(t) + "\u00b0C"
    }

    function weekdayShort(dateStr) {
        // Noon avoids timezone shifting the day.
        const d = new Date(dateStr + "T12:00:00")
        const names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return names[d.getDay()]
    }

    function refresh() {
        if (fetch.running)
            return
        fetch.running = false
        fetch.running = true
    }

    function refreshCity() {
        if (geoFetch.running)
            return
        geoFetch.running = false
        geoFetch.running = true
    }

    function parse(text) {
        if (!text || text.trim() === "")
            return
        let data = null
        try {
            data = JSON.parse(text)
        } catch (e) {
            return
        }
        const current = data?.current
        if (current) {
            const g = root.glyphFor(current.weather_code)
            const t = root.formatTemperature(current.temperature_2m)
            if (g !== "")
                root.glyph = g
            if (t !== "")
                root.temperature = t
        }
        const daily = data?.daily
        if (daily && daily.time) {
            let list = []
            for (let i = 0; i < daily.time.length; i++) {
                list.push({
                    weekday: root.weekdayShort(daily.time[i]),
                    glyph: root.glyphFor(daily.weather_code[i]),
                    max: Math.round(daily.temperature_2m_max[i]),
                    min: Math.round(daily.temperature_2m_min[i])
                })
            }
            root.forecast = list
        }
    }

    function parseCity(text) {
        if (!text || text.trim() === "")
            return
        let data = null
        try {
            data = JSON.parse(text)
        } catch (e) {
            return
        }
        const c = data?.city || data?.locality || data?.principalSubdivision || ""
        const k = data?.countryName || ""
        if (c !== "")
            root.city = c
        if (k !== "")
            root.country = k
    }

    Process {
        id: fetch
        command: ["curl", "-s", "--max-time", "10", root.endpoint]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
        onExited: {
            if (root.temperature === "")
                retryTimer.restart()
        }
    }

    Process {
        id: geoFetch
        command: ["curl", "-sL", "--max-time", "10", root.geoEndpoint]
        stdout: StdioCollector {
            onStreamFinished: root.parseCity(this.text)
        }
    }

    Timer {
        interval: 1800000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: retryTimer
        interval: 60000; repeat: false
        onTriggered: root.refresh()
    }

    // Refresh as soon as connectivity comes back (also covers post-resume).
    Connections {
        target: NetworkStatusService
        function onWifiNetworkChanged() {
            if (NetworkStatusService.wifiNetwork !== "") {
                Qt.callLater(root.refresh)
                if (root.city === "")
                    Qt.callLater(root.refreshCity)
            }
        }
    }

    Component.onCompleted: {
        root.refresh()
        root.refreshCity()
    }
}
