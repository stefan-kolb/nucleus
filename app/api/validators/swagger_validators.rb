class IsArray < Grape::Validations::Base
  def validate_param!(attr_name, params)
    # no validation required
  end
end

class Required < Grape::Validations::Base
  def validate_param!(attr_name, params)
    # no validation required
  end
end
