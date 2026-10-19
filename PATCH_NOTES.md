# Patch Notes

## 2026-10-19: Chart reliability and regression coverage

- Replaced `Date.UTC` birth-time conversion, which silently remapped years 1-99 to 1901-1999, with explicit Gregorian UTC date construction and offset rollover handling.
- Validated birth dates, time, coordinates, UTC offset, house system, and zodiac before changing active chart state.
- Limited chart years to the embedded ephemeris range (1550-2650) and made the year field reflect that range.
- Sanitized restored localStorage values so malformed visits, notes, and saved birth details fall back safely instead of crashing startup.
- Centralized Whole Sign cusp construction and wraparound house-sector lookup; exact cusp boundaries now consistently belong to the following house.
- Added nine Node regression tests covering leap years, years 1-99 conversion, offset/day rollover, malformed saved state, invalid input, cusp boundaries, and ephemeris house assignments.
- Added project documentation for chart inputs, run/test commands, and custom DOM events.

Validation: `npm test` passes all 9 regression tests; inline browser module syntax is checked separately with Node.

## 2026-10-19: Elm chart insights

- Replaced the empty Elm subscription shell with a flags-driven `Browser.element` that can mount as an embedded launcher or as a standalone details app.
- Added an Elm launcher button on the wheel page that opens `chart-insights.html` through a navigation port.
- Added Overview, Elements, Key Insights, Transits, Horoscope, and Pricing tabs backed by the locally saved chart summary.
- Kept Horoscope and Pricing intentionally empty and marked Transits as not yet calculated.
- Added `npm run build:elm`, the generated bundle ignore rule, and docs for embedding and navigation.