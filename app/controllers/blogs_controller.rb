# -*- coding: utf-8 -*-

require 'json'
require 'date'
require 'fluent-logger'

LOG_PATH = "/home/fluent/.fluent/log"

class BlogsController < ApplicationController
  def index
    @approot_path = Rails.env.production? ? "/newscloud/" : "/"
    @search_path = @approot_path + "search"
    @blogs_path = @approot_path + "blogs"
    open_blogs('index')
    get_wordcount

    respond_to do |format|
      format.html
      format.json { render json: @blogs }
    end
  end

  def json
    open_blogs('json')
    render :json => @blogs
  end

  def edit
    @blog = Blog.find(params[:id])
  end

  private

  def open_blogs(method)
    @blogs = Hash.new{|h,k| h[k] = Hash.new(&h.default_proc)}

    if params[:date]
      begin
        pickup_date = Date.strptime(params[:date], "%Y%m%d")
      rescue ArgumentError
        pickup_date = Date.today - 1
      end
    else
      pickup_date = Date.today - 1
    end

    @today = pickup_date.strftime("%Y%m%d")
    @prev  = (pickup_date - 1).strftime("%Y%m%d")
    @next  = (pickup_date + 1).strftime("%Y%m%d")

    infile = logpath("hotnews_#{@today}.txt")
    if File.exist?(infile)
      open_file(infile)
    else
      @blogs = []
    end

    if Rails.env.production?
      @fluentd = Fluent::Logger::FluentLogger.open('newscloud',
        host = 'localhost', port = 9999)
      @fluentd.post('show', {
        :date => @today,
        :records => @blogs.length,
        :method => method
      })
    end
  end

  def logpath(log_name)
    File.expand_path(File.join(LOG_PATH, log_name))
  end

  def open_file(infile)
    open(infile) do |file|
      file.each_line do |line|
        id, score, title, link, category = line.strip.split("\t")
        scoring(id, score, title, link, category)
      end
    end
    @blogs = @blogs.sort_by{|k,v| -v['score']}
  end

  def scoring(id, score, title, link, category)
    @blogs[link]['id'] = id unless id.nil?
    @blogs[link]['title'] = title unless title.nil?
    @blogs[link]['score'] = score.to_i unless score.nil?
    case category
    when 'social'
      @blogs[link]['category'] = '社会'
    when 'politics'
      @blogs[link]['category'] = '政治'
    when 'international'
      @blogs[link]['category'] = '国際'
    when 'economics'
      @blogs[link]['category'] = '経済'
    when 'electro'
      @blogs[link]['category'] = '電脳'
    when 'sports'
      @blogs[link]['category'] = 'スポーツ'
    when 'entertainment'
      @blogs[link]['category'] = 'エンタメ'
    when 'science'
      @blogs[link]['category'] = '科学'
    else
      @blogs[link]['category'] = '不明'
    end
  end

  def get_wordcount
    wordcount_txt = logpath("wordcount_#{@today}.txt")
    @wordcount = Hash.new
    if File.exist?(wordcount_txt)
      open_wordcount(wordcount_txt)
    end
  end

  def open_wordcount(wordcount_txt)
    open(wordcount_txt) do |file|
      file.each_line do |line|
        id, word, count = line.strip.split("\t")
        @wordcount[word] = count
      end
    end
  end
end
