if current_user.has_role?(:admin, @project)
	json.extract! @project, :id, :name, :project_key, :issuer, :keypass, :created_at, :updated_at
else
	json.extract! @project, :id, :name, :created_at, :updated_at
end
