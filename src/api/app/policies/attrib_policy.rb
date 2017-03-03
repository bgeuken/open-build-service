class AttribPolicy < ApplicationPolicy
  def create?
    # Admins can write everything
    return true if @user.is_admin?

    modifiables = get_modifiables
    if modifiables.empty? && @record.container.present?
      # No specific rules set for the attribute, check if the user can modify the container
      return @user.can_modify_project?(@record.container) if @record.container.kind_of? Project
      return @user.can_modify_package?(@record.container)
    else
      # check for modifiable_by rules
      has_permissions_for_modifiables?(modifiables)
    end
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  private

  # Parses AttribTypeModifiableBy and AttribNamespaceModifiableBy association
  # collections and checks the users permissions.
  #
  # Permission check is based on:
  #   - User
  #   - Group association of user
  #   - Role association of user (Only for AttribTypeModifiableBy)
  def has_permissions_for_modifiables?(attrib_modifiable_bies)
    attrib_modifiable_bies.to_a.any? do |rule|
      rule.user == @user ||
      @user.is_in_group?(rule.group) ||
        (rule.try(:role) && @user.has_local_role?(rule.role, @record.container))
    end
  end

  # Collects AttribTypeModifiableBy and AttribNamespaceModifiableBy associated to
  #  an AttribType object and returns them in an Array
  def get_modifiables
    modifiables = @record.attrib_type.try(:attrib_type_modifiable_bies).to_a
    if @record.attrib_type.try(:attrib_namespace)
      modifiables + @record.attrib_type.attrib_namespace.attrib_namespace_modifiable_bies.to_a
    else
      modifiables
    end
  end
end
