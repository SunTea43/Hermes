class ApplicationService
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs, &block).call
  end

  def call
    raise NotImplementedError, "#{self.class.name} must implement #call"
  end
end
