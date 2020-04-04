# frozen_string_literal: true

#
# Helpers methods
#
module Helpers
  def check_token_sequence(output, expected_output)
    valid = true
    count = 0
    output.each do |token|
      if expected_output[count].key?(token.type) &&
         expected_output[count].value?(token.value)
      else
        valid = false
      end
      count += 1
    end
    valid
  end
end
