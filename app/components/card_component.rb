# frozen_string_literal: true

class CardComponent < ApplicationComponent
  def initialize(title: nil, css_class: nil)
    @title = title
    @css_class = css_class
  end
end
