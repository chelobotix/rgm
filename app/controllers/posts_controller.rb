class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def show
    @post = Post.find(params[:id])
  end

  def create
    post = Post.new(post_params)
    post.user = current_user
    post.words = 1000

    if post.save
      redirect_to posts_path, notice: "Post created successfully"
    else
      redirect_to posts_path, alert: "Post creation failed: #{post.errors.full_messages.join(", ")}"
    end
  end

  def update
    @post = Post.find(params[:id])
    @post.update(post_params)
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
  end

  def editor
    @post = Post.new
  end

  private
  def post_params
    params
      .require(:post)
      .permit(
        :title_en,
        :title_es,
        :title_pt,
        :description_en,
        :description_es,
        :description_pt,
        :body_en,
        :body_es,
        :body_pt,
        :image_url,
        :thumbnail_url,
        :tags, :words,
        :user_id
      )
  end
end
