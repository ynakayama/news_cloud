# -*- coding: utf-8 -*-

require 'json'
require 'date'
require 'sysadmin'
require 'fluent-logger'

SEARCH_PATH = "/home/fluent/.fluent/log"

class SearchController < ApplicationController
  def index
    pickup_date = Date.today - 1
    @today = pickup_date.strftime("%Y%m%d")
  end

  def create
    pickup_date = Date.today - 1
    @today = pickup_date.strftime("%Y%m%d")
    @blogs = Sysadmin::Util.create_multi_dimensional_hash
    return if params[:search_string].blank?
    @search_path = Rails.env.production? ? "/newscloud/search" : "/search"
    filelists = Sysadmin::Directory.new(SEARCH_PATH).grep(/hotnews*./)
    begin
      rule = Regexp.new(params[:search_string], Regexp::IGNORECASE)
      filelists.each do |infile|
        open(infile) do |file|
           file.each_line do |line|
             id, score, title, link, category = line.strip.split("\t")
             day = File::basename(infile).delete(".txt").delete("hotnews_")
             scoring(id, score, title, link, category, day) if rule =~ title
           end
        end
      end
    rescue RegexpError
    end
    @blogs = @blogs.sort_by{|k,v| -v['score']}

    if Rails.env.production?
      @fluentd = Fluent::Logger::FluentLogger.open('newscloud',
        host = 'localhost', port = 9999)
      @fluentd.post('search', {
        :word => params[:search_string],
        :records => @blogs.length
      })
    end
  end

  private

  def scoring(id, score, title, link, category, day)
    @blogs[link]['id'] = id unless id.nil?
    @blogs[link]['title'] = title unless title.nil?
    @blogs[link]['score'] = score.to_i unless score.nil?
    @blogs[link]['day'] = day unless day.nil?
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
end
