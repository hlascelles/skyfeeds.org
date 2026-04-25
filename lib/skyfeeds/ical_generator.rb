require "icalendar"
require "fileutils"
require_relative "eclipse" # Corrected require path

module Skyfeeds
  class IcalGenerator
    class << self
      # Changed parameter name to 'event' for generality and to handle different types
      def build_event(event)
        ical_event = Icalendar::Event.new

        # Determine date and time
        date_obj = event.date
        # Use event.time if available (for eclipses), otherwise default to noon UTC for celestial events
        time_obj = event.respond_to?(:time) && event.time ? event.time : Time.parse("#{date_obj}T12:00:00Z")

        date_str = date_obj.strftime("%Y-%m-%d")
        time_str = time_obj.strftime("%H:%M:%S")
        datetime = DateTime.parse("#{date_str}T#{time_str}")

        ical_event.dtstart = datetime
        ical_event.dtstamp = datetime

        # Build components using helper methods that handle different event types
        ical_event.summary = build_summary(event)
        ical_event.uid = build_uid(event, date_str, time_str)
        ical_event.description = build_description(event)
        ical_event.url = build_url(event) # Use a helper method for URL

        ical_event
      end

      # Helper to build summary, distinguishing between Eclipse and CelestialEvent
      def build_summary(event)
        if event.is_a?(Skyfeeds::Eclipse)
          "#{event.type.to_s.capitalize} #{event.category.to_s.capitalize} Eclipse"
        elsif event.is_a?(Skyfeeds::CelestialEvent)
          event.event_name.capitalize # Use event name for celestial events
        else
          "Unknown Event" # Fallback
        end
      end

      # Helper to build UID, distinguishing between Eclipse and CelestialEvent
      def build_uid(event, date_str, time_str)
        if event.is_a?(Skyfeeds::Eclipse)
          uid = "#{date_str}-#{time_str}-#{event.type}-#{event.category}"
        elsif event.is_a?(Skyfeeds::CelestialEvent)
          # Create a UID based on event type and name for celestial events
          uid_base = "#{event.event_type.to_s.downcase.gsub('_', '-')}-#{event.event_name.downcase.gsub(/[^a-z0-9]+/, '-')}"
          uid = "#{date_str}-#{time_str}-#{uid_base}"
        else
          uid = "#{date_str}-#{time_str}-unknown-event"
        end
        uid.downcase.tr(" ", "_")
      end

      # Helper to build description, distinguishing between Eclipse and CelestialEvent
      def build_description(event)
        if event.is_a?(Skyfeeds::Eclipse)
          summary = build_summary(event) # Re-use summary builder
          description = "Type: #{summary}"

          if event.region && !event.region.empty?
            description += "
Region: #{format_region(event.region)}"
          end

          description += "
Countries: #{event.countries.join(', ')}" if event.countries&.any?
          description += "
More info: #{build_url(event)}" if build_url(event) # Only add if URL exists
          description
        elsif event.is_a?(Skyfeeds::CelestialEvent)
          # For CelestialEvent, use its direct description and event name, and potentially event type
          event_type_formatted = event.event_type.to_s.gsub('_', ' ').capitalize
          description = "Type: #{event_type_formatted}
Name: #{event.event_name}
"
          description += event.description # Add the description from CSV
          # Celestial events from CSV don't have a direct structured URL.
          description
        else
          "No description available."
        end
      end

      # Helper to build URL, distinguishing between Eclipse and CelestialEvent
      def build_url(event)
        if event.is_a?(Skyfeeds::Eclipse)
          # Use the existing method on Eclipse object if it exists
          event.url
        elsif event.is_a?(Skyfeeds::CelestialEvent)
          # Celestial events from CSV don't have a direct URL field or generation logic like eclipses.
          nil
        else
          nil
        end
      end

      def format_region(region)
        # Expand NASA single-letter directional abbreviations (s Africa → S. Africa)
        region.gsub(/\b(?<dir>[nsewc]) /) do
          "#{Regexp.last_match[:dir].upcase}. "
        end
      end

      # New method to create and write the calendar file
      def create_calendar(events, filename, output_dir)
        calendar = Icalendar::Calendar.new
        events.each do |event|
          calendar.add_event(build_event(event))
        end

        # Ensure directory exists
        FileUtils.mkdir_p(File.join(output_dir, File.dirname(filename)))

        # Write the calendar to the specified file
        File.write(File.join(output_dir, filename), calendar.to_ical)
      end
    end
  end
end
