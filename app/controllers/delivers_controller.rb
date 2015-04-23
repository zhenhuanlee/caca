class DeliversController < ApplicationController
  def index
    @delivers = current_user.delivers
    @deliver = current_user.deliver
  end

  def new
    @deliver = Deliver.new
  end

  def create
    @deliver = current_user.delivers.build( deliver_params )
    if @deliver.save
      flash[:success] = '地址添加成功'
      redirect_to delivers_path
    else
      render :new
    end
  end

  def apply
    @deliver = Deliver.where.not(user: current_user).confirmed.take!
    @deliver.apply! do
      @deliver.update(owner: current_user)
    end
    flash[:success] = "您已获取到新地址"
    redirect_to delivers_path
  end

  private
  def deliver_params
    params.require(:deliver).permit(:name, :phone, :province, :city, :district, :town, :address, :zip)
  end
end
