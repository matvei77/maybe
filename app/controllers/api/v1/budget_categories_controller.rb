# frozen_string_literal: true

class Api::V1::BudgetCategoriesController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization for read vs write access
  before_action :ensure_read_scope, only: [ :index ]
  before_action :ensure_write_scope, only: [ :update ]
  before_action :set_budget
  before_action :set_budget_category, only: [ :update ]

  def index
    # Get all budget categories for this budget
    budget_categories_query = @budget.budget_categories.includes(:category)
    
    # Order by category name
    budget_categories_query = budget_categories_query.joins(:category).order("categories.name")

    # Handle pagination with Pagy
    @pagy, @budget_categories = pagy(
      budget_categories_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    # Make per_page available to the template
    @per_page = safe_per_page_param

    # Rails will automatically use app/views/api/v1/budget_categories/index.json.jbuilder
    render :index

  rescue => e
    Rails.logger.error "BudgetCategoriesController#index error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def update
    if @budget_category.update(budget_category_params)
      render :show
    else
      render json: {
        error: "validation_failed",
        message: "Budget category could not be updated",
        errors: @budget_category.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "BudgetCategoriesController#update error: #{e.message}"
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
        start_date = Budget.param_to_date(params[:budget_month_year])
      rescue ArgumentError
        render json: {
          error: "not_found",
          message: "Invalid budget month_year format"
        }, status: :not_found
        return
      end
      
      @budget = family.budgets.find_by(start_date: start_date.beginning_of_month)
      
      unless @budget
        render json: {
          error: "not_found",
          message: "Budget not found"
        }, status: :not_found
      end
    end
    
    def set_budget_category
      @budget_category = @budget.budget_categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: "not_found",
        message: "Budget category not found"
      }, status: :not_found
    end

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def budget_category_params
      params.require(:budget_category).permit(:budgeted_spending)
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