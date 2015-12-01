require 'yaml'
require 'active_support/all'

module Weeels
  class Keen
    require 'keen'

    def initialize
      client
    end

    def client
      @client ||= new_client
    end

    def new_client
      hash = YAML.load(File.read("keen.yml")).symbolize_keys[:weeels].symbolize_keys
      ::Keen::Client.new(
        read_timeout: 300,
        project_id: hash[:project_id],
        read_key: hash[:read_key]
      )
    end
  end
end
