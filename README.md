# Skyfeeds.org

### Format of the eclipse ical filenames

For all solar eclipses:
solar/solar_eclipse_all.ics
solar/solar_eclipse_partial.ics
solar/solar_eclipse_total.ics
solar/solar_eclipse_annular.ics

For continents:
solar/africa/solar_eclipse_africa_all.ics
solar/africa/solar_eclipse_africa_partial.ics
solar/africa/solar_eclipse_africa_total.ics
solar/africa/solar_eclipse_africa_annular.ics
... and so on for all continents

For countries you just do the total solar eclipses:
solar/mexico/solar_eclipse_mexico_total.ics
... and so on for all countries

For lunar eclipses it is a lot simpler:
lunar/lunar_eclipse_all.ics
lunar/lunar_eclipse_partial.ics
lunar/lunar_eclipse_penumbral.ics
lunar/lunar_eclipse_total.ics

### The ICAl files

The uid should not have spaces in it.

### Generating the iCal files

To regenerate the files, just run:

`bundle exec rspec`

Or just run the tests in VSCode.

### Use of sorbet-runtime

This project uses T::Enum classes. They are not strings. To convert them to strings, you can use
the `to_s` method.
