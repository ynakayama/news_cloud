# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../spec_helper'

describe BlogsController, 'ブログ' do
  fixtures :all

  context 'にアクセスすると' do
    describe '一覧表示' do
      it "一覧画面が表示される" do
        get 'index'
        response.should be_success
      end
    end

  end
end
