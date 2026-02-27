# Copilot Instructions for skyfeeds.org

## Project Overview
This is a Ruby project that generates iCal (`.ics`) calendar feeds and a static HTML page for upcoming solar and lunar eclipses. The output is served via GitHub Pages from the `docs/` directory. The main entry point is `rake` (default task), which runs `Skyfeeds::EclipsesProcessor.run`.

## Architecture
- **`config/solar_eclipses.csv`** and **`config/lunar_eclipses.csv`** — source data for all eclipses.
- **`lib/skyfeeds/`** — all library code, namespaced under `Skyfeeds`:
  - `eclipse.rb` — `Eclipse` struct, `EclipseCategory` and `EclipseType` enums (Sorbet-typed).
  - `constants.rb` — continent constants.
  - `solar_eclipses_reader.rb` / `lunar_eclipses_reader.rb` — parse CSVs and return `Array<Eclipse>`.
  - `eclipses_processor.rb` — orchestrates reading, generating `.ics` files, and rendering HTML.
- **`views/index.erb`** — ERB template rendered with Erubis to produce `docs/index.html`.
- **`docs/`** — generated output directory (GitHub Pages root). Do not hand-edit files here.

## Key Libraries
- **Sorbet runtime** (`sorbet-runtime`) — used for `T::Sig`, `T::Struct`, `T::Enum`. Always add `sig` blocks on public methods and use typed structs/enums where appropriate.
- **Icalendar** — builds `.ics` calendar files.
- **Erubis** — renders ERB templates.
- **ActiveSupport** — time zone handling (`Time.zone`).

## Ruby & Sorbet Conventions
- Target Ruby: 3.2+.
- All code lives in the `Skyfeeds` module.
- Use Sorbet's `T::Struct` (with `const`) instead of plain `Struct` or `Data`.
- Use `T::Enum` for enumerated types; define `to_s` and `downcase` helpers as needed.
- Extend classes with `T::Sig` and annotate public methods with `sig { ... }` blocks.
- No `frozen_string_literal` magic comment required (disabled in Rubocop config).

## Style Rules (Rubocop)
- **Quotes**: double quotes for strings (`Style/StringLiterals: double_quotes`).
- **Line length**: max 100 characters.
- **Trailing commas**: required in multiline arrays and hashes.
- **Dot position**: leading (`.method` on the next line, not trailing).
- **Access modifiers**: inline style (`private def foo`).
- **No Rails-specific cops** are enforced (this is not a Rails app).
- Run `bundle exec rubocop` to check; `bundle exec rubocop -A` to auto-correct.

## Code Quality Tools
All checks are run via the CI workflow (`.github/workflows/specs.yml`) on pull requests.

- **Tests**: `./specs.sh` → `bundle exec rspec`
- **Linting & quality**: `./quality.sh` → runs `fasterer`, `rubocop`, and `reek` in sequence.
- **Reek** limits: max 15 methods per class, max 15 statements per method, max 4 params (5 for `initialize`), no duplicate method calls (>3), no nested iterators (>2 deep).

## Adding New Eclipse Types or Data
1. Update the CSV source file in `config/`.
2. If adding a new `EclipseType`, add it to the enum in `lib/skyfeeds/eclipse.rb` and update `totalish?` if relevant.
3. Update `SolarEclipsesReader` or `LunarEclipsesReader` to parse any new CSV columns.
4. Update the ERB template in `views/` if the HTML output needs to change.
5. Add or update RSpec examples in `spec/`.

## Testing
- Test files live in `spec/` and mirror the lib structure.
- `spec/spec_helper.rb` calls `EclipsesProcessor.clean_output_dir` before the suite runs.
- Integration-style specs (e.g. `eclipses_processor_spec.rb`) call `.run` and assert output files exist.
- Use `rspec` conventions: `described_class`, `let`, `expect(...).to`.
