# frozen_string_literal: true

module RedmineAIWriter
  # Hooks for Redmine AI Writer plugin.
  class Hooks < Redmine::Hook::ViewListener
    # Renders the 'Generate Content' button on the issue view page.
    #
    # This hook is triggered at the bottom of the issue details block,
    # just before the description.
    # It will only render the button if the user has the required permission
    # and the issue's tracker matches the one configured in the settings.
    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      project = context[:project]
      settings = Setting.plugin_redmine_ai_writer

      # Check for permission and correct tracker
      return unless User.current.allowed_to?(:use_ai_writer, project)
      return unless issue.tracker_id.to_s == settings['tracker_id']

      context[:controller].render_to_string(
        partial: 'hooks/view_issues_show_details_bottom',
        locals: context.merge(settings: settings)
      )
    end
  end
end 
