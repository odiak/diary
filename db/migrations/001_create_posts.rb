Sequel.migration do
  up do
    create_table(:posts) do
      primary_key :id
      String :title, default: ""
      String :body, text: true, default: ""
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end

  down do
    drop_table(:posts)
  end
end
