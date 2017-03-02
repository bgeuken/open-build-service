class AttribTypePolicy < ApplicationPolicy
  def create?
    @user.is_admin? || has_access_to_type? || has_access_to_namespace?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  private

  def has_access_to_type?
    @record.attrib_type_modifiable_bies.any? do |rule|
      rule.user == @user || @user.is_in_group?(rule.group)
    end
  end

  def has_access_to_namespace?
    @record.attrib_namespace.attrib_namespace_modifiable_bies.any? do |rule|
      rule.user == @user || @user.is_in_group?(rule.group)
    end
  end
end
