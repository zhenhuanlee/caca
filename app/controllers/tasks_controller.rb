class TasksController < ApplicationController
  before_action :authenticate_user!
  def index
    @tasks = Task.pending
  end

  def new
    # 数据自动填充: 来自模版->上次成功纪录->新内容
    if params[:template]
      @task = Task.new(JSON.parse(current_user.templates.find(params[:template]).content))
    elsif cookies[:task_param]
      @task = Task.new(JSON.parse(cookies[:task_param]))
    else
      @task = Task.new(receive_time: true, comment_time: true)
    end

    @shops = current_user.shops.confirmed

    if @shops.blank?
      flash[:error] = '发布任务前需要绑定店铺掌柜'
      redirect_to shops_path
      return
    end

    if current_user.frozen_amount < 100
      flash[:error] = '发布任务前需要申请冻结资金100元'
      redirect_to deposits_path
      return
    end

    unless ['checked', 'officialed'].include?(current_user.state)
      flash[:error] = '发布任务前需要进行账户认证'
      redirect_to edit_authenticates_path
      return
    end
  end


  def create
    @task = current_user.tasks.build(task_param)
    if @task.save
      flash[:success] = "任务发布成功"
      cookies[:task_param] = JSON.generate(task_param)
      redirect_to my_task_path
    else
      @shops = current_user.shops.confirmed
      render :new
    end
  end

  def show
    @task = Task.find(params[:id])
    @shops = current_user.shops.confirmed
    render :new
  end

  def validate
    @task = Task.find(params[:id])
    if @task.link.match(/id=\d+/) == params[:link].match(/id=\d+/)
      @task.apply!
      flash[:success] = '宝贝地址验证成功'
    else
      flash[:error] = '宝贝地址验证失败'
    end
    redirect_to task_path(@task)
  end

  def my
    @pending_count = current_user.tasks.pending.count
    @talking_count = current_user.tasks.talking.count
    @confirmed_count = current_user.tasks.confirmed.count
    @applying_count = current_user.tasks.applying.count
    @all_count = current_user.tasks.count

    if %w(pending talking confirmed applying).include?( params[:type] )
      @tasks = current_user.tasks.send(params[:type].to_sym)
    else
      @tasks = current_user.tasks
    end
  end

  def destroy
    current_user.tasks.find(params[:id]).destroy
    flash[:success] = '任务取消成功'
    redirect_to my_task_path
  end


  private
    def task_param
      params.require(:task).permit!
    end

end
