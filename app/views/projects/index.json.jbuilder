json.array!(@projects) do |project|
  json.extract! project, :id, :name, :project_key
  json.url project_url(project, format: :json)
end
