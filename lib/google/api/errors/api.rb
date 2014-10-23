# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

module GoogleApi
  
  class ApiError < StandardError
    
    attr_reader :result
  
    def initialize(result)
      @result = result
    end
    
  end

end