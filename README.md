# Skyfeeds.org

Welcome to **Skyfeeds.org**, your source for upcoming solar and lunar eclipses in iCal format.

The final site is hosted at: [https://www.skyfeeds.org/](https://www.skyfeeds.org/)

## Overview

Skyfeeds.org provides comprehensive iCal (`.ics`) feeds for solar and lunar eclipses, allowing you to easily subscribe to these celestial events in your favorite calendar application (Google Calendar, Apple Calendar, Outlook, etc.).

### Key Features

*   **Global Feeds**: Subscribe to all solar and lunar eclipses worldwide.
*   **Regional Filtering**: Find solar eclipses specifically visible from your continent or country.
*   **Celestial Events Feeds**: Combined feeds for specific locations that include all total-ish solar eclipses and all lunar eclipses.
*   **Local Time Calculation**: The website calculates peak times in local timezones for countries to help you plan your viewing.
*   **Detailed Descriptions**: Each calendar event includes the eclipse type, visibility region, and a link to more detailed information.

## Data Source

The eclipse data is processed from NASA's [Sky Events Calendar](https://eclipse.gsfc.nasa.gov/SKYCAL/SKYCAL.html) by Fred Espenak and Sumit Dutta.

## Development

This is an open-source project. You can find the source code on GitHub at [https://github.com/hlascelles/skyfeeds.org](https://github.com/hlascelles/skyfeeds.org).

### Building

To build the static website and generate the iCal files, run:

```bash
bundle install
bundle exec rake default
```

This will process the source CSV files in `config/` and output the generated site to the `docs/` directory, which is served via GitHub Pages.

### Quality and Testing

We use `rubocop`, `reek`, and `fasterer` for code quality, and `rspec` for testing.

*   Run linter: `./quality.sh`
*   Run tests: `./specs.sh`
