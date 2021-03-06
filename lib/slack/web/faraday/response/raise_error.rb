# frozen_string_literal: true
module Slack
  module Web
    module Faraday
      module Response
        class RaiseError < ::Faraday::Response::Middleware
          def on_complete(env)
            raise Slack::Web::Api::Errors::TooManyRequestsError, env.response if env.status == 429
            raise Slack::Web::Api::Errors::SlackError.new("Invalid JSON received from Slack API.", env.response) if !body.is_a?(Hash)
            return unless (body = env.body) && !body['ok']

            error_message =
              body['error'] || body['errors'].map { |message| message['error'] }.join(',')
            raise Slack::Web::Api::Errors::SlackError.new(error_message, env.response)
          end
        end
      end
    end
  end
end
