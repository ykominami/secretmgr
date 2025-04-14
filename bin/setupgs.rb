require 'yaml'
require 'pathname'

def resolve_paths_in_yaml(template_path, output_path, top_dir)
  begin
    template_data = YAML.load_file(template_path)
  rescue Psych::SyntaxError => e
    puts "エラー: テンプレートYAMLファイルの構文が正しくありません (#{template_path}): #{e.message}"
    return
  rescue Errno::ENOENT
    puts "エラー: テンプレートYAMLファイルが見つかりません (#{template_path})"
    return
  end

  resolved_data = {}
  template_data.each do |key, value|
    if value.is_a?(String)
      resolved_data[key] = File.join(top_dir, value)
    elsif value.is_a?(Array)
      resolved_data[key] = value.map { |item| item.is_a?(String) ? (Pathname.new(top_dir) + item).expand_path.to_s : item }
    else
      resolved_data[key] = value
    end
  end

  begin
    File.open(output_path, 'w') do |f|
      YAML.dump(resolved_data, f)
    end
    puts "処理完了: フルパスに解決されたYAMLファイルが #{output_path} に出力されました。"
  rescue Errno::EACCES
    puts "エラー: 出力YAMLファイルへの書き込み権限がありません (#{output_path})"
  rescue StandardError => e
    puts "エラー: 出力YAMLファイルへの書き込み中にエラーが発生しました (#{output_path}): #{e.message}"
  end
end

resolve_paths_in_yaml(ARGV[0], ARGV[1], ARGV[2])

# 使用例:
# 以下のファイル構成を想定
# /tmp/
#   template.yaml
#   data/
#     file1.txt
#     file2.txt
#
# template.yaml の内容例:
# file_path: data/file1.txt
# image_paths:
#   - data/image1.png
#   - data/image2.png
# config:
#   setting1: value1
#   setting2: value2

# resolve_paths_in_yaml('/tmp/template.yaml', '/tmp/output.yaml', '/tmp')
#
# /tmp/output.yaml の内容例:
# file_path: /tmp/data/file1.txt
# image_paths:
# - /tmp/data/image1.png
# - /tmp/data/image2.png
# config:
#   setting1: value1
#   setting2: value2