# frozen_string_literal: true

class PageHeaderComponent < ApplicationComponent
  def initialize(title:, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end
end
