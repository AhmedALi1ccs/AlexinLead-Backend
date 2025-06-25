module Api
  module V1
    class ScreenMaintenancesController < ApplicationController
      before_action :set_screen
      before_action :set_maintenance, only: [:update, :destroy]

      def create
        maint = @screen.screen_maintenances.build(maint_params)
        if maint.save
          render json: serialize(maint), status: :created
        else
          render json: { errors: maint.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @maintenance.update(maint_params)
          render json: serialize(@maintenance)
        else
          render json: { errors: @maintenance.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @maintenance.destroy
        head :no_content
      end

      private

      def set_screen
        @screen = ScreenInventory.find(params[:screen_inventory_id])
      end

      def set_maintenance
        @maintenance = @screen.screen_maintenances.find(params[:id])
      end

      def maint_params
        params.require(:screen_maintenance).permit(:sqm, :maintenance_start_date, :maintenance_end_date)
      end

      def serialize(maint)
        {
          id: maint.id,
          screen_inventory_id: maint.screen_inventory_id,
          sqm: maint.sqm,
          maintenance_start_date: maint.maintenance_start_date,
          maintenance_end_date: maint.maintenance_end_date
        }
      end
    end
  end
end
