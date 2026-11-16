#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "tmpdir"
require "yaml"

script = File.expand_path("apply_renamed_models.rb", __dir__)
spec = <<~YAML
  openapi: 3.0.3
  components:
    schemas:
      QueryCallMembersResponse:
        type: object
        properties:
          sort:
            $ref: '#/components/schemas/SortParamRequest'
      SortParamRequest:
        type: object
      Response:
        type: object
      VideoEvent:
        discriminator:
          mapping:
            call.response: '#/components/schemas/Response'
            call.external: other.yaml#/components/schemas/Response
        properties:
          payload:
            $ref: '#/components/responses/Response'
          external:
            $ref: other.yaml#/components/schemas/Response
  paths:
    /video/members:
      get:
        responses:
          "200":
            content:
              application/json:
                schema:
                  $ref: '#/components/schemas/QueryCallMembersResponse'
YAML
renames = <<~JSON
  {
    "QueryCallMembersResponse": "QueryMembersResponse",
    "Response": "ModelResponse",
    "SortParam": "SortParamRequest",
    "TimeStats": "Stats"
  }
JSON

Dir.mktmpdir do |dir|
  spec_path = File.join(dir, "spec.yaml")
  renames_path = File.join(dir, "renames.json")
  output_path = File.join(dir, "out.yaml")
  File.write(spec_path, spec)
  File.write(renames_path, renames)

  stdout, stderr, status = Open3.capture3(
    "ruby", script, spec_path, renames_path, output_path
  )
  abort("script failed\n#{stdout}#{stderr}") unless status.success?

  output = File.read(output_path)
  abort("old schema key remains\n#{output}") if output.include?("QueryCallMembersResponse:")
  abort("new schema key missing\n#{output}") unless output.include?("QueryMembersResponse:")
  abort("ref not renamed\n#{output}") if output.include?("schemas/QueryCallMembersResponse")
  abort("ref missing\n#{output}") unless output.include?("schemas/QueryMembersResponse")
  abort("Response schema remains\n#{output}") if output.match?(/^    Response:/)
  abort("ModelResponse missing\n#{output}") unless output.include?("ModelResponse:")
  abort("SortParamRequest schema duplicated or lost\n#{output}") unless output.scan("SortParamRequest:").size == 1
  abort("expected skip notice\n#{stdout}") unless stdout.include?("skip SortParam")
  abort("expected skip notice\n#{stdout}") unless stdout.include?("skip TimeStats")

  document = YAML.load_file(output_path)
  event = document.dig("components", "schemas", "VideoEvent")
  mapping = event.dig("discriminator", "mapping")
  abort("discriminator target not renamed\n#{output}") unless mapping["call.response"] == "#/components/schemas/ModelResponse"
  abort("external mapping changed\n#{output}") unless mapping["call.external"] == "other.yaml#/components/schemas/Response"
  payload = event.dig("properties", "payload", "$ref")
  abort("response component ref changed\n#{output}") unless payload == "#/components/responses/Response"
  external = event.dig("properties", "external", "$ref")
  abort("external schema ref changed\n#{output}") unless external == "other.yaml#/components/schemas/Response"
end

puts "apply_renamed_models_test: ok"
