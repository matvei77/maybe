# frozen_string_literal: true

class Api::V1::CategoriesController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization for read vs write access
  before_action :ensure_read_scope, only: [ :index, :show ]
  before_action :ensure_write_scope, only: [ :create, :update, :destroy, :bootstrap ]
  before_action :set_category, only: [ :show, :update, :destroy ]

  def index
    family = current_resource_owner.family
    categories_query = family.categories

    # Apply filters
    categories_query = apply_filters(categories_query)

    # Apply search
    categories_query = apply_search(categories_query) if params[:search].present?

    # Include necessary associations for efficient queries
    categories_query = categories_query.includes(:parent, :subcategories).alphabetically

    # Handle pagination with Pagy
    @pagy, @categories = pagy(
      categories_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    # Make per_page available to the template
    @per_page = safe_per_page_param

    # Rails will automatically use app/views/api/v1/categories/index.json.jbuilder
    render :index

  rescue => e
    Rails.logger.error "CategoriesController#index error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def show
    # Rails will automatically use app/views/api/v1/categories/show.json.jbuilder
    render :show

  rescue => e
    Rails.logger.error "CategoriesController#show error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def create
    family = current_resource_owner.family
    @category = family.categories.new(category_params)

    if @category.save
      render :show, status: :created
    else
      render json: {
        error: "validation_failed",
        message: "Category could not be created",
        errors: @category.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "CategoriesController#create error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def update
    if @category.update(category_params)
      render :show
    else
      render json: {
        error: "validation_failed",
        message: "Category could not be updated",
        errors: @category.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "CategoriesController#update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def destroy
    @category.destroy!

    render json: {
      message: "Category deleted successfully"
    }, status: :ok

  rescue => e
    Rails.logger.error "CategoriesController#destroy error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def bootstrap
    family = current_resource_owner.family
    
    # Bootstrap default categories for the family
    default_categories = [
      [ "Income", "#e99537", "circle-dollar-sign", "income" ],
      [ "Loan Payments", "#6471eb", "credit-card", "expense" ],
      [ "Fees", "#6471eb", "credit-card", "expense" ],
      [ "Entertainment", "#df4e92", "drama", "expense" ],
      [ "Food & Drink", "#eb5429", "utensils", "expense" ],
      [ "Shopping", "#e99537", "shopping-cart", "expense" ],
      [ "Home Improvement", "#6471eb", "house", "expense" ],
      [ "Healthcare", "#4da568", "pill", "expense" ],
      [ "Personal Care", "#4da568", "pill", "expense" ],
      [ "Services", "#4da568", "briefcase", "expense" ],
      [ "Gifts & Donations", "#61c9ea", "hand-helping", "expense" ],
      [ "Transportation", "#df4e92", "bus", "expense" ],
      [ "Travel", "#df4e92", "plane", "expense" ],
      [ "Rent & Utilities", "#db5a54", "lightbulb", "expense" ]
    ]
    
    default_categories.each do |name, color, icon, classification|
      family.categories.find_or_create_by!(name: name) do |category|
        category.color = color
        category.classification = classification
        category.lucide_icon = icon
      end
    end

    # Return all categories after bootstrap
    @categories = family.categories.includes(:parent, :subcategories).alphabetically
    @pagy = Pagy.new(count: @categories.count, limit: 100, page: 1)
    @per_page = 100

    render :index

  rescue => e
    Rails.logger.error "CategoriesController#bootstrap error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  private

    def set_category
      family = current_resource_owner.family
      @category = family.categories.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: "not_found",
        message: "Category not found"
      }, status: :not_found
    end

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def apply_filters(query)
      # Classification filtering
      if params[:classification].present?
        query = query.where(classification: params[:classification])
      end

      # Parent filtering (only root categories)
      if params[:roots_only].present? && params[:roots_only] == "true"
        query = query.roots
      end

      # Parent ID filtering
      if params[:parent_id].present?
        query = query.where(parent_id: params[:parent_id])
      end

      query
    end

    def apply_search(query)
      search_term = "%#{params[:search]}%"
      query.where("name ILIKE ?", search_term)
    end

    def category_params
      params.require(:category).permit(:name, :color, :parent_id, :classification, :lucide_icon)
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