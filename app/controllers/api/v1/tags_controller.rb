# frozen_string_literal: true

class Api::V1::TagsController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization for read vs write access
  before_action :ensure_read_scope, only: [ :index, :show ]
  before_action :ensure_write_scope, only: [ :create, :update, :destroy ]
  before_action :set_tag, only: [ :show, :update, :destroy ]

  def index
    family = current_resource_owner.family
    tags_query = family.tags

    # Apply search
    tags_query = apply_search(tags_query) if params[:search].present?

    # Include necessary associations for efficient queries
    tags_query = tags_query.includes(:transactions).alphabetically

    # Handle pagination with Pagy
    @pagy, @tags = pagy(
      tags_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    # Make per_page available to the template
    @per_page = safe_per_page_param

    # Rails will automatically use app/views/api/v1/tags/index.json.jbuilder
    render :index

  rescue => e
    Rails.logger.error "TagsController#index error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def show
    # Rails will automatically use app/views/api/v1/tags/show.json.jbuilder
    render :show

  rescue => e
    Rails.logger.error "TagsController#show error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def create
    family = current_resource_owner.family
    @tag = family.tags.new(tag_params)

    # Set default color if not provided
    if @tag.color.blank?
      @tag.color = Tag::COLORS.sample
    end

    if @tag.save
      render :show, status: :created
    else
      render json: {
        error: "validation_failed",
        message: "Tag could not be created",
        errors: @tag.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "TagsController#create error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def update
    if @tag.update(tag_params)
      render :show
    else
      render json: {
        error: "validation_failed",
        message: "Tag could not be updated",
        errors: @tag.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "TagsController#update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def destroy
    @tag.destroy!

    render json: {
      message: "Tag deleted successfully"
    }, status: :ok

  rescue => e
    Rails.logger.error "TagsController#destroy error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  private

    def set_tag
      family = current_resource_owner.family
      @tag = family.tags.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: "not_found",
        message: "Tag not found"
      }, status: :not_found
    end

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def apply_search(query)
      search_term = "%#{params[:search]}%"
      query.where("name ILIKE ?", search_term)
    end

    def tag_params
      params.require(:tag).permit(:name, :color)
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