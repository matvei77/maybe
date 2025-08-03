# frozen_string_literal: true

class Api::V1::TransfersController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization for read vs write access
  before_action :ensure_read_scope, only: [ :index, :show ]
  before_action :ensure_write_scope, only: [ :create, :update, :destroy, :confirm, :reject ]
  before_action :set_transfer, only: [ :show, :update, :destroy, :confirm, :reject ]

  def index
    family = current_resource_owner.family
    
    # Get transfers through transactions that belong to the family
    transfers_query = Transfer.joins(:inflow_transaction)
                             .where(transactions: { entry_id: family.entries.select(:id) })

    # Apply filters
    transfers_query = apply_filters(transfers_query)

    # Include necessary associations for efficient queries
    transfers_query = transfers_query.includes(
      inflow_transaction: { entry: :account },
      outflow_transaction: { entry: :account }
    ).order(created_at: :desc)

    # Handle pagination with Pagy
    @pagy, @transfers = pagy(
      transfers_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    # Make per_page available to the template
    @per_page = safe_per_page_param

    # Rails will automatically use app/views/api/v1/transfers/index.json.jbuilder
    render :index

  rescue => e
    Rails.logger.error "TransfersController#index error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def show
    # Rails will automatically use app/views/api/v1/transfers/show.json.jbuilder
    render :show

  rescue => e
    Rails.logger.error "TransfersController#show error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def create
    family = current_resource_owner.family
    
    @transfer = Transfer::Creator.new(
      family: family,
      source_account_id: transfer_params[:from_account_id],
      destination_account_id: transfer_params[:to_account_id],
      date: transfer_params[:date],
      amount: transfer_params[:amount].to_d
    ).create

    if @transfer.persisted?
      render :show, status: :created
    else
      render json: {
        error: "validation_failed",
        message: "Transfer could not be created",
        errors: @transfer.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "TransfersController#create error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def update
    Transfer.transaction do
      # Update category on the outflow transaction if transfer supports categorization
      if transfer_update_params[:category_id].present? && @transfer.categorizable?
        @transfer.outflow_transaction.update!(category_id: transfer_update_params[:category_id])
      end
    end

    render :show

  rescue => e
    Rails.logger.error "TransfersController#update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def destroy
    @transfer.destroy!

    render json: {
      message: "Transfer deleted successfully"
    }, status: :ok

  rescue => e
    Rails.logger.error "TransfersController#destroy error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def confirm
    @transfer.confirm!

    render :show

  rescue => e
    Rails.logger.error "TransfersController#confirm error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def reject
    @transfer.reject!

    render json: {
      message: "Transfer rejected successfully"
    }, status: :ok

  rescue => e
    Rails.logger.error "TransfersController#reject error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  private

    def set_transfer
      family = current_resource_owner.family
      
      # Find the transfer and ensure the family owns it
      @transfer = Transfer
                    .joins(:inflow_transaction)
                    .where(id: params[:id])
                    .where(transactions: { entry_id: family.entries.select(:id) })
                    .first
                    
      unless @transfer
        render json: {
          error: "not_found",
          message: "Transfer not found"
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
      # Status filtering
      if params[:status].present?
        query = query.where(status: params[:status])
      end

      # Date range filtering
      if params[:start_date].present?
        query = query.joins(inflow_transaction: :entry)
                     .where("entries.date >= ?", Date.parse(params[:start_date]))
      end

      if params[:end_date].present?
        query = query.joins(inflow_transaction: :entry)
                     .where("entries.date <= ?", Date.parse(params[:end_date]))
      end

      # Account filtering
      if params[:account_id].present?
        query = query.joins(
          inflow_transaction: :entry,
          outflow_transaction: :entry
        ).where(
          "entries.account_id = ? OR entries_transactions_2.account_id = ?",
          params[:account_id], params[:account_id]
        )
      end

      query
    end

    def transfer_params
      params.require(:transfer).permit(:from_account_id, :to_account_id, :amount, :date)
    end
    
    def transfer_update_params
      params.require(:transfer).permit(:category_id)
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