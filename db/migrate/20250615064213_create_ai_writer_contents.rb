# frozen_string_literal: true

# Migration to create the ai_writer_contents table for storing generated content.
class CreateAiWriterContents < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_writer_contents do |t|
      t.references :issue, foreign_key: true, null: false, index: true, type: :integer
      t.references :author, foreign_key: { to_table: :users }, null: false, type: :integer
      t.text :user_prompt
      t.text :system_prompt
      t.text :generated_content
      t.timestamps
    end
  end
end
