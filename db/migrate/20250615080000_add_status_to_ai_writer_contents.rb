class AddStatusToAiWriterContents < ActiveRecord::Migration[6.1]
  def change
    add_column :ai_writer_contents, :status, :integer, default: 0, null: false
  end
end 
