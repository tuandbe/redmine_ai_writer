Redmine::Plugin.register :redmine_ai_writer do
  name 'Redmine AI Writer'
  author 'tuandbe'
  description 'This is a plugin for Redmine that uses AI to write content for issues.'
  version '0.0.1'
  url 'https://github.com/tuandbe/redmine_ai_writer'
  author_url 'https://github.com/tuandbe'

  requires_redmine version_or_higher: '5.0.0'

  settings default: {
    'openai_api_key' => '',
    'tracker_id' => '12',
    'prompt_custom_field_id' => '',
    'prompt_template_custom_field_id' => '',
    'system_prompt' => 'Write a post for your business to be published on any social media platform, based on the provided title and user prompt.'
  }, partial: 'settings/ai_writer_settings'

  project_module :ai_writer do
    permission :use_ai_writer, { ai_writer: [:generate_content, :apply_content, :update_content] }, require: :member
  end

  # Register hooks
  require_dependency File.join(File.dirname(__FILE__), 'lib', 'redmine_ai_writer', 'hooks.rb')

  # Apply patches using a robust method
  begin
    patch_module_fqn = 'RedmineAiWriter::Patches::IssuePatch'

    patch_file_absolute_path = File.join(
      File.dirname(__FILE__),
      'lib',
      'redmine_ai_writer',
      'patches',
      'issue_patch.rb'
    )

    require_dependency patch_file_absolute_path

    patch_module = patch_module_fqn.constantize
    target_class = Issue

    unless target_class.included_modules.include?(patch_module)
      target_class.send(:include, patch_module)
      # Add a log to confirm that the patch was applied during startup
      Rails.logger.info "[AI Writer Plugin] Successfully patched Issue model with #{patch_module_fqn}."
    end

  rescue LoadError => e
    Rails.logger.error "[AI Writer Plugin] Error loading IssuePatch. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue NameError => e
    Rails.logger.error "[AI Writer Plugin] Error finding Issue or IssuePatch module. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue StandardError => e
    Rails.logger.error "[AI Writer Plugin] Error applying IssuePatch. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  end
end
