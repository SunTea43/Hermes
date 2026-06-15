class RoleAssignmentsController < ApplicationController
  before_action :set_role_assignment, only: %i[ show edit update destroy ]

  # GET /role_assignments or /role_assignments.json
  def index
    @role_assignments = RoleAssignment.all
  end

  # GET /role_assignments/1 or /role_assignments/1.json
  def show
  end

  # GET /role_assignments/new
  def new
    @role_assignment = RoleAssignment.new
  end

  # GET /role_assignments/1/edit
  def edit
  end

  # POST /role_assignments or /role_assignments.json
  def create
    @role_assignment = RoleAssignment.new(role_assignment_params)

    respond_to do |format|
      if @role_assignment.save
        format.html { redirect_to @role_assignment, notice: "Role assignment was successfully created." }
        format.json { render :show, status: :created, location: @role_assignment }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @role_assignment.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /role_assignments/1 or /role_assignments/1.json
  def update
    respond_to do |format|
      if @role_assignment.update(role_assignment_params)
        format.html { redirect_to @role_assignment, notice: "Role assignment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @role_assignment }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @role_assignment.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /role_assignments/1 or /role_assignments/1.json
  def destroy
    @role_assignment.destroy!

    respond_to do |format|
      format.html { redirect_to role_assignments_path, notice: "Role assignment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role_assignment
      @role_assignment = RoleAssignment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def role_assignment_params
      params.expect(role_assignment: [ :user_id, :business_id, :role, :assigned_modules, :restrictions, :assigned_at, :ended_at, :status ])
    end
end
