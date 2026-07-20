class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update ]
  before_action :set_manageable_businesses, only: %i[ new edit create update ]

  def index
    @users = policy_scope(User).includes(:owned_businesses, role_assignments: :business).order(:name, :email)
  end

  def show
    authorize @user
    @role_assignments = @user.role_assignments.includes(:business).order(status: :asc, role: :asc)
  end

  def new
    @user = User.new(status: "active")
    authorize @user
  end

  def edit
    authorize @user
  end

  def create
    @user = User.new(user_attributes)
    authorize @user

    if create_user_with_initial_role
      redirect_to @user, notice: "Usuario creado correctamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @user

    if update_user_and_roles
      redirect_to @user, notice: "Usuario actualizado correctamente.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = User.find(params.expect(:id))
  end

  def set_manageable_businesses
    @manageable_businesses = current_user.manageable_businesses.order(:name)
  end

  def user_attributes
    permitted = user_params.except(:initial_business_id, :initial_role)
    return permitted if permitted[:password].present?

    permitted.except(:password, :password_confirmation)
  end

  def user_params
    params.expect(user: [
      :name,
      :email,
      :whatsapp_phone,
      :status,
      :default_whatsapp_business_id,
      :password,
      :password_confirmation,
      :initial_business_id,
      :initial_role
    ])
  end

  def initial_role_params
    user_params.slice(:initial_business_id, :initial_role)
  end

  def update_user_and_roles
    updated = false
    attributes = user_attributes
    default_business_submitted = attributes.key?(:default_whatsapp_business_id)
    default_business_id = attributes.delete(:default_whatsapp_business_id)

    ActiveRecord::Base.transaction do
      unless @user.update(attributes)
        raise ActiveRecord::Rollback
      end

      if should_sync_permitted_roles?
        sync_permitted_roles
      end

      if should_sync_whatsapp_role_access?
        sync_whatsapp_role_access
      end

      if default_business_submitted &&
          !@user.update(default_whatsapp_business_id: default_business_id.presence)
        raise ActiveRecord::Rollback
      end

      updated = true
    end

    updated
  end

  def should_sync_permitted_roles?
    @user != current_user && params.dig(:user, :permitted_roles).present?
  end

  def sync_permitted_roles
    @manageable_businesses.each do |business|
      selected_role = permitted_role_for(business)
      unless selected_role.blank? || RoleAssignment::ROLES.include?(selected_role)
        @user.errors.add(:base, "Rol inválido para #{business.name}.")
        raise ActiveRecord::Rollback
      end

      current_assignments = @user.role_assignments.where(business: business, status: "active")

      current_assignments.find_each do |assignment|
        authorize assignment, :update?
        assignment.update!(status: "inactive", ended_at: Time.current)
      end

      next if selected_role.blank?

      assignment = @user.role_assignments.find_or_initialize_by(business: business, role: selected_role)
      assignment.assign_attributes(status: "active", ended_at: nil, assigned_at: assignment.assigned_at || Time.current)
      authorize assignment, :update?
      assignment.save!
    end
  end

  def permitted_role_for(business)
    params.dig(:user, :permitted_roles, business.id.to_s)
  end

  def should_sync_whatsapp_role_access?
    params.fetch(:user, {}).key?(:whatsapp_business_ids)
  end

  def sync_whatsapp_role_access
    selected_ids = Array(params.dig(:user, :whatsapp_business_ids))
      .compact_blank
      .map(&:to_i)

    @manageable_businesses.each do |business|
      assignments = @user.role_assignments.where(
        business: business,
        status: "active"
      )

      if selected_ids.include?(business.id)
        assignment = assignments.first
        unless assignment
          @user.errors.add(
            :base,
            "El usuario debe tener un rol activo en #{business.name} antes de habilitar WhatsApp."
          )
          raise ActiveRecord::Rollback
        end

        unless assignment.whatsapp_enabled?
          assignment.update!(
            whatsapp_enabled: true,
            whatsapp_authorized_by: current_user,
            whatsapp_authorized_at: Time.current
          )
        end
      else
        assignments.where(whatsapp_enabled: true).find_each do |assignment|
          assignment.update!(whatsapp_enabled: false)
        end
      end
    end
  end

  def create_user_with_initial_role
    initial_role = initial_role_params
    if initial_role[:initial_business_id].blank? || initial_role[:initial_role].blank?
      @user.errors.add(:base, "Selecciona un negocio y rol inicial.")
      return false
    end

    created = false

    ActiveRecord::Base.transaction do
      unless @user.save
        raise ActiveRecord::Rollback
      end

      role_assignment = @user.role_assignments.build(
        business_id: initial_role[:initial_business_id],
        role: initial_role[:initial_role],
        status: "active",
        assigned_at: Time.current
      )
      authorize role_assignment

      unless role_assignment.save
        role_assignment.errors.full_messages.each { |message| @user.errors.add(:base, message) }
        raise ActiveRecord::Rollback
      end

      created = true
    end

    created
  end
end
