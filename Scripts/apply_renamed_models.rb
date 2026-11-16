#!/usr/bin/env ruby
# frozen_string_literal: true

# Renames component schema keys in a published OpenAPI document.
# GetStream/protocol publishes the v1 video client spec under the backend
# schema names. Scripts/renamed-models.json is the Swift name map previously
# applied by `generate-spec -renamed-models`.

require "json"
require "yaml"

spec_path, renames_path, output_path = ARGV
if [spec_path, renames_path, output_path].any? { |arg| arg.nil? || arg.empty? }
  warn "usage: apply_renamed_models.rb <spec.yaml> <renames.json> <output.yaml>"
  exit 1
end

spec = YAML.load_file(spec_path)
renames = JSON.parse(File.read(renames_path))
schemas = spec.dig("components", "schemas")
unless schemas.is_a?(Hash)
  warn "spec has no components.schemas"
  exit 1
end

applied = {}
renames.each do |old_name, new_name|
  unless schemas.key?(old_name)
    puts "skip #{old_name}: schema is not in the spec"
    next
  end
  if old_name != new_name && schemas.key?(new_name)
    warn "cannot rename #{old_name} to #{new_name}: target schema already exists"
    exit 1
  end
  schemas[new_name] = schemas.delete(old_name)
  applied[old_name] = new_name
  puts "rename #{old_name} -> #{new_name}"
end

def rewrite_refs(node, applied)
  case node
  when Hash
    node.each do |key, value|
      if key == "$ref" && value.is_a?(String)
        name = value.split("/").last
        node[key] = "#/components/schemas/#{applied[name]}" if applied.key?(name)
      else
        rewrite_refs(value, applied)
      end
    end
  when Array
    node.each { |value| rewrite_refs(value, applied) }
  end
end

rewrite_refs(spec, applied)
File.write(output_path, YAML.dump(spec))
