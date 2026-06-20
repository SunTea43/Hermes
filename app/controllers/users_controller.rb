class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update ]
  before_action :set_manageable_businesses, only: %i[ new create ]

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

    if @user.update(user_attributes)
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
      :password,
      :password_confirmation,
      :initial_business_id,
      :initial_role
    ])
  end

  def initial_role_params
    user_params.slice(:initial_business_id, :initial_role)
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
