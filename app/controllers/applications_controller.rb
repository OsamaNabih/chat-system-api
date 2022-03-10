class ApplicationsController < ApplicationController
  before_action :set_application, except: [:index, :create]
  before_action :block_blank_name, only: [:create, :update]

  def index
    apps = Application.connection.select_all("SELECT token, chats_count, created_at, updated_at FROM applications")
    render json: apps
  end

  def show
    render json: @app.as_json(except: ["id", "next_chat_number"])
  end

  def create
    @app = Application.new(application_params)
    if @app.save
      render json: {msg: "Application created successfully", token: @app[:token]}, status: :ok
    else
      render json: {msg: "Application creation failed. Please double check the data provided"}, status: :unprocessable_entity
    end
  end

  def update
    if Application.update(@app.id, application_params)
      render json: {msg: "Application updated successfully"}, status: :ok
    else
      render json: {msg: @app.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def destroy
    #Application.destroy(@app.id)
    AppSoftDeletionJob.perform_later
    render json: {msg: "Application destroyed successfully"}, status: :ok
  end

  private
    def application_params
      params.require(:application).permit(:name)
    end

    # Since creation will be delegated to a worker
    # We need to infer the success of the request before assigning it to queue
    def block_blank_name
      if params[:name].to_s.strip.empty?
        render json: {msg: "Name must not be empty"}, status: :unprocessable_entity
      end
    end

    def set_application
      super
    end
end
