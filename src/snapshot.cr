require "file_utils"
require "time"
require "./snap_file"

module Ss
  class Snapshot
    property directory : String
    property id : String?
    property timestamp : String

    @total_items = 0
    @current_item = 0
    @progress_callback : Proc(Float32, Nil)?

    def initialize(@directory, @id = nil)
      @timestamp = Time.utc.to_unix.to_s
    end

    def set_progress_callback(&block : Float32 ->)
      @progress_callback = block
    end

    def save : String
      home_dir = Path.home.to_s
      ss_dir = File.join(home_dir, ".ss")
      Dir.mkdir_p(ss_dir) unless Dir.exists?(ss_dir)

      count_items(@directory)
      snap_data = build_snapshot_data(@directory)

      snap_file = SnapFile.new(snap_data)
      encrypted_data = snap_file.encrypt

      filename = "#{timestamp}-#{@id || "snap"}.snap"
      filepath = File.join(ss_dir, filename)

      File.write(filepath, encrypted_data)

      filename
    end

    private def build_snapshot_data(path : String) : Hash(String, JSON::Any)
      data = {
        "metadata" => JSON::Any.new({
          "timestamp" => JSON::Any.new(timestamp),
          "id"        => JSON::Any.new(@id || "snap"),
          "directory" => JSON::Any.new(File.expand_path(@directory)),
        }),
        "structure" => JSON::Any.new(build_structure(path))
      }

      data
    end

    private def count_items(path : String)
      if File.directory?(path)
        Dir.each_child(path) do |entry|
          entry_path = File.join(path, entry)
          if File.directory?(entry_path)
            count_items(entry_path)
          end
          @total_items += 1
        end
      end
    end

    private def build_structure(path : String) : Array(JSON::Any)
      structure = [] of JSON::Any

      if File.directory?(path)
        Dir.each_child(path) do |entry|
          entry_path = File.join(path, entry)

          if File.directory?(entry_path)
            structure << JSON::Any.new({
              "type"  => JSON::Any.new("directory"),
              "name"  => JSON::Any.new(entry),
              "path"  => JSON::Any.new(entry_path),
              "contents" => JSON::Any.new(build_structure(entry_path))
            })
          else
            structure << JSON::Any.new({
              "type"  => JSON::Any.new("file"),
              "name"  => JSON::Any.new(entry),
              "path"  => JSON::Any.new(entry_path),
              "size"  => JSON::Any.new(File.size(entry_path)),
              "content" => JSON::Any.new(Base64.strict_encode(File.read(entry_path)))
            })
          end

          @current_item += 1
          update_progress
        end
      end

      structure
    end

    private def update_progress
      if callback = @progress_callback
        progress = @current_item.to_f32 / @total_items.to_f32
        callback.call(progress)
      end
    end
  end
end
