# frozen_string_literal: true

class Api::V1::BudgetsController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization for read vs write access
  before_action :ensure_read_scope, only: [ :index, :show ]
  before_action :ensure_write_scope, only: [ :create, :update ]
  before_action :set_budget, only: [ :show, :update ]

  def index
    family = current_resource_owner.family
    
    # Get all budgets for the family
    budgets_query = family.budgets

    # Apply filters
    budgets_query = apply_filters(budgets_query)

    # Order by start date descending (most recent first)
    budgets_query = budgets_query.order(start_date: :desc)

    # Handle pagination with Pagy
    @pagy, @budgets = pagy(
      budgets_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    # Make per_page available to the template
    @per_page = safe_per_page_param

    # Rails will automatically use app/views/api/v1/budgets/index.json.jbuilder
    render :index

  rescue => e
    Rails.logger.error "BudgetsController#index error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def show
    # Rails will automatically use app/views/api/v1/budgets/show.json.jbuilder
    render :show

  rescue => e
    Rails.logger.error "BudgetsController#show error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def create
    family = current_resource_owner.family
    
    # Parse the start_date
    begin
      start_date = Date.parse(budget_params[:start_date])
    rescue ArgumentError
      render json: {
        error: "validation_failed",
        message: "Invalid start_date format",
        errors: ["Start date must be a valid date"]
      }, status: :unprocessable_entity
      return
    end
    
    # Check if budget date is valid
    unless Budget.budget_date_valid?(start_date, family: family)
      render json: {
        error: "validation_failed",
        message: "Invalid budget date",
        errors: ["Budget date must be within valid range"]
      }, status: :unprocessable_entity
      return
    end
    
    # Find or bootstrap the budget
    @budget = Budget.find_or_bootstrap(family, start_date: start_date)
    
    # Update with provided parameters
    if @budget.update(budget_params.except(:start_date))
      render :show, status: :created
    else
      render json: {
        error: "validation_failed",
        message: "Budget could not be created",
        errors: @budget.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "BudgetsController#create error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def update
    if @budget.update(budget_update_params)
      render :show
    else
      render json: {
        error: "validation_failed",
        message: "Budget could not be updated",
        errors: @budget.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "BudgetsController#update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  private

    def set_budget
      family = current_resource_owner.family
      
      # Handle special param format (month_year like "jan-2024")
      begin
        start_date = Budget.param_to_date(params[:month_year])
      rescue ArgumentError
        render json: {
          error: "not_found",
          message: "Invalid budget month_year format"
        }, status: :not_found
        return
      end
      
      @budget = Budget.find_or_bootstrap(family, start_date: start_date)
      
      unless @budget
        render json: {
          error: "not_found",
          message: "Budget not found or invalid date"
        }, status: :not_found
      end
    end

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def apply_filters(query)
      # Year filtering
      if params[:year].present?
        year = params[:year].to_i
        start_of_year = Date.new(year, 1, 1)
        end_of_year = Date.new(year, 12, 31)
        query = query.where(start_date: start_of_year..end_of_year)
      end

      # Status filtering (initialized vs uninitialized)
      if params[:initialized].present?
        if params[:initialized] == "true"
          query = query.where.not(budgeted_spending: nil)
        else
          query = query.where(budgeted_spending: nil)
        end
      end

      query
    end

    def budget_params
      params.require(:budget).permit(:start_date, :budgeted_spending, :expected_income)
    end
    
    def budget_update_params
      params.require(:budget).permit(:budgeted_spending, :expected_income)
    end

    def safe_page_param
      page = params[:page].to_i
      page > 0 ? page : 1
    end

    def safe_per_page_param
      per_page = params[:per_page].to_i
      case per_page
      when 1..100
        per_page
      else
        25  # Default
      end
    end
end