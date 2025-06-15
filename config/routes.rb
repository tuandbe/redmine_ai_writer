# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# frozen_string_literal: true

post 'issues/:issue_id/ai_writer/generate', to: 'ai_writer#generate_content', as: 'ai_writer_generate_content'
post 'issues/:issue_id/ai_writer/apply/:content_id', to: 'ai_writer#apply_content', as: 'ai_writer_apply_content'
patch 'ai_writer_contents/:content_id', to: 'ai_writer#update_content', as: 'ai_writer_update_content'
