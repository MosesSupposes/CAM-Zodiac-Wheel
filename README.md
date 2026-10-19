# Cam Zodiac Wheel

An interactive natal chart and reflection journal. The browser frontend uses the MIT-licensed `@astrologer/ephemera` package for planetary positions and house calculations.

## Run

Install dependencies with `npm install`, then serve this directory over HTTP. For example:

```sh
npm run build:elm
python3 -m http.server 8000
```

Open `http://localhost:8000/Your%20zodiac%20wheel.html`.
The wheel's **Explore my chart** button opens `chart-insights.html` as its own page.
The Elm frontend is a `Browser.element`: it mounts into `#chartInsightsLauncher` on the wheel page and into `#chartDetails` on the standalone page. Rebuild it after changing Elm with `npm run build:elm`.

Run regression tests with:

```sh
npm test
```

## Chart Inputs

- The embedded ephemeris data is intended for years 1550 through 2650; the form rejects years outside that range.
- Enter the birth-time UTC offset that applied at the birthplace on that date. The app does not infer historical daylight-saving rules from the coordinates.
- House system and zodiac are independent settings: Placidus or Whole Sign houses, and Tropical or Lahiri Sidereal zodiac.
- Whole Sign houses begin at 0 degrees of the sign containing the Ascendant. Placidus uses computed cusps; at unsupported polar latitudes the ephemeris can fall back to Porphyry.
- The optional name is stored locally with chart details. Reflections remain on the device in localStorage.

## Custom Events

The app dispatches document-level `CustomEvent`s:

- `zodiac:chart-ready`: `{ houseSystem, zodiacMode, ascendant, cusps, placements }`
- `zodiac:house-change`: `{ house, cusp, houseSystem, zodiacMode }`
- `zodiac:wheel-spin-start`: `{ fromHouse, toHouse, houseSystem, zodiacMode }`
- `zodiac:wheel-spin-end`: `{ house, cusp, houseSystem, zodiacMode }`

Longitudes and cusps in event details are degrees in the selected zodiac. Placement house numbers are one-based. Events do not include the user's name, birth date, birth time, or location.

## Chart Insights

The Elm insights page has Overview, Elements, Key Insights, Transits, Horoscope, and Pricing tabs. Overview, Elements, and Key Insights use the saved calculated chart summary. Transits currently explains that calculations are not available; Horoscope and Pricing are intentionally empty placeholders.