# frozen_string_literal: true

module RedmineAiWriter
  module Patches
    # Patches the Issue model to automatically generate a prompt for child issues.
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        # Single unified callback runs for both create and update right before saving.
        before_save :ai_writer_generate_prompt_if_needed
      end

      private

      # Unified callback: generate prompt whenever the current prompt field is blank.
      def ai_writer_generate_prompt_if_needed
        begin
          Rails.logger.debug "--- [AI Writer Patch | SAVE] ---"

          prompt_cf_id = Setting.plugin_redmine_ai_writer['prompt_custom_field_id']&.to_i
          template_cf_id = Setting.plugin_redmine_ai_writer['prompt_template_custom_field_id']&.to_i
          return if prompt_cf_id.blank? || template_cf_id.blank?

          cv = self.custom_values.detect { |v| v.custom_field_id == prompt_cf_id }
          # Do nothing if prompt already has content
          if cv&.value.present?
            Rails.logger.debug "[AI Writer Patch | SAVE] EXIT: Prompt already present."
            return
          end

          # Determine parent issue (handle both create and update)
          parent_id_current = self.parent_id
          parent_id_current = self.changes['parent_id']&.last if parent_id_current.blank?
          unless parent_id_current.present?
            Rails.logger.debug "[AI Writer Patch | SAVE] EXIT: No parent issue."
            return
          end

          parent_issue = Issue.find_by(id: parent_id_current)
          unless parent_issue
            Rails.logger.debug "[AI Writer Patch | SAVE] EXIT: Cannot load parent ##{parent_id_current}."
            return
          end

          # Subject is available on both create and update at this point
          subject_text = self.subject.to_s
          ai_writer_generate_and_assign_prompt(parent_issue, subject_text)
        rescue => e
          Rails.logger.error "[AI Writer Patch|SAVE] UNEXPECTED ERROR: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end

      # Shared helper method. It now requires `subject` to be passed in.
      def ai_writer_generate_and_assign_prompt(parent_issue, subject)
        Rails.logger.debug "[AI Writer Patch|HELPER] ENTERED for parent ##{parent_issue&.id}, subject '#{subject}'"
        
        settings = Setting.plugin_redmine_ai_writer
        prompt_cf_id = settings['prompt_custom_field_id']&.to_i
        template_cf_id = settings['prompt_template_custom_field_id']&.to_i
        
        return unless prompt_cf_id.positive? && template_cf_id.positive? && parent_issue && subject.present?
        
        prompt_cf = CustomField.find_by(id: prompt_cf_id)
        template_cf = CustomField.find_by(id: template_cf_id)
        return unless prompt_cf && template_cf
        
        return unless self.tracker.custom_fields.include?(prompt_cf)
        return unless parent_issue.tracker.custom_fields.include?(template_cf)

        template = parent_issue.custom_value_for(template_cf)&.value
        return if template.blank?

        cleaned_desc = ""
        if self.project.description.present?
          html_desc = self.project.description
          text_with_newlines = html_desc.gsub(/<br\s*\/?>/i, "\n").gsub(/<\/p>|<\/div>|<\/h[1-6]>/i, "\n")
          plain_text = ActionController::Base.helpers.strip_tags(text_with_newlines)
          cleaned_desc = plain_text.gsub(/\n{3,}/, "\n\n").strip
        end

        filled_prompt = template.gsub('{issue_title}', "`#{subject}`")
                                .gsub('{project_name}', "`#{self.project.name}`")
                                .gsub('{project_desciption}', "\"\"\"#{cleaned_desc}\"\"\"")
        
        # Use Redmine's helper method which properly marks custom field values as changed
        self.custom_field_values = { prompt_cf_id => filled_prompt }

        Rails.logger.debug "[AI Writer Patch|HELPER] SUCCESS: Assigned prompt to CF ##{prompt_cf_id}."
      end
    end
  end
end 
