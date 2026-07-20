class RoleAssignmentsController < ApplicationController
  before_action :set_role_assignment, only: %i[ show edit update destroy ]
  before_action :set_form_options, only: %i[ new edit create update ]

  def index
    @role_assignments = policy_scope(RoleAssignment).includes(:user, :business).order(status: :asc, role: :asc)
  end

  def show
    authorize @role_assignment
  end

  def new
    @role_assignment = RoleAssignment.new(
      user_id: params[:user_id],
      business: @manageable_businesses.first,
      status: "active",
      assigned_at: Time.current
    )
    authorize @role_assignment
  end

  def edit
    authorize @role_assignment
  end

  def create
    @role_assignment = RoleAssignment.new(role_assignment_params)
    authorize @role_assignment
    apply_whatsapp_authorization_metadata

    respond_to do |format|
      if @role_assignment.save
        format.html { redirect_to role_assignment_redirect_path, notice: "Rol asignado correctamente." }
        format.json { render :show, status: :created, location: @role_assignment }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @role_assignment.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @role_assignment
    @role_assignment.assign_attributes(role_assignment_params)
    authorize @role_assignment
    apply_whatsapp_authorization_metadata

    respond_to do |format|
      if @role_assignment.save
        format.html { redirect_to role_assignment_redirect_path, notice: "Rol actualizado correctamente.", status: :see_other }
        format.json { render :show, status: :ok, location: @role_assignment }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @role_assignment.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @role_assignment
    user = @role_assignment.user
    @role_assignment.destroy!

    respond_to do |format|
      format.html { redirect_to user_path(user), notice: "Rol eliminado correctamente.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_role_assignment
    @role_assignment = RoleAssignment.find(params.expect(:id))
  end

  def set_form_options
    @manageable_businesses = current_user.manageable_businesses.order(:name)
    @users = policy_scope(User).order(:name, :email)
  end

  def role_assignment_params
    params.expect(role_assignment: [ :user_id, :business_id, :role, :assigned_modules, :restrictions, :assigned_at, :ended_at, :status, :whatsapp_enabled ])
  end

  def apply_whatsapp_authorization_metadata
    return unless @role_assignment.whatsapp_enabled_changed?

    if @role_assignment.whatsapp_enabled?
      @role_assignment.whatsapp_authorized_by = current_user
      @role_assignment.whatsapp_authorized_at = Time.current
    else
      @role_assignment.whatsapp_authorized_by = nil
      @role_assignment.whatsapp_authorized_at = nil
    end
  end

  def role_assignment_redirect_path
    user_path(@role_assignment.user)
  end
end
