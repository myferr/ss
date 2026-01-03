require "file_utils"

module Ss
  class Loader
    property snapshot_data : Hash(String, JSON::Any)
    property target_dir : String

    @total_items = 0
    @current_item = 0
    @progress_callback : Proc(Float32, Nil)?

    def initialize(snapshot_filename, @target_dir, passphrase : String? = nil)
      home_dir = Path.home.to_s
      snapshot_path = File.join(home_dir, ".ss", snapshot_filename)

      encrypted_content = File.read(snapshot_path)
      # Initialize to empty hash to satisfy Crystal's type system
      @snapshot_data = Hash(String, JSON::Any).new
      
      begin
        @snapshot_data = SnapFile.decrypt(encrypted_content, passphrase)
      rescue ex : OpenSSL::Cipher::Error
        puts "Error: Failed to decrypt snapshot. The passphrase may be incorrect."
        puts "If this snapshot was created with a passphrase, use --passphrase to provide it."
        raise "Decryption failed"
      end
    end

    def set_progress_callback(&block : Float32 ->)
      @progress_callback = block
    end

    def preview
      print_structure(@snapshot_data["structure"].as_a, "")
    end

    def load(confirm = true)
      if confirm
        print "You sure you want to load snapshot (y/N)?: "
        input = gets
        if input && input.strip.downcase != "y"
          puts "Cancelled."
          return
        end
      end

      Dir.mkdir_p(@target_dir) unless Dir.exists?(@target_dir)

      restore_structure(@snapshot_data["structure"].as_a, @target_dir)
    end

    def load_with_progress(confirm = true)
      if confirm
        print "You sure you want to load #{@target_dir == Dir.current ? "this snapshot" : "snapshot"} (y/N)?: "
        input = gets
        if input && input.strip.downcase != "y"
          puts "Cancelled."
          return
        end
      end

      count_items(@snapshot_data["structure"].as_a)

      Dir.mkdir_p(@target_dir) unless Dir.exists?(@target_dir)

      restore_structure_with_progress(@snapshot_data["structure"].as_a, @target_dir)

      puts "\rLoaded!"
    end

    private def count_items(structure : Array(JSON::Any))
      structure.each do |item|
        item_hash = item.as_h
        type = item_hash["type"].as_s

        if type == "directory"
          contents = item_hash["contents"]?.try(&.as_a) || [] of JSON::Any
          count_items(contents)
        end

        @total_items += 1
      end
    end

    private def print_structure(structure : Array(JSON::Any), prefix : String)
      structure.each do |item|
        item_hash = item.as_h
        name = item_hash["name"].as_s
        type = item_hash["type"].as_s

        puts "#{prefix}#{name}"

        if type == "directory"
          contents = item_hash["contents"]?.try(&.as_a) || [] of JSON::Any
          print_structure(contents, prefix + "  ")
        end
      end
    end

    private def restore_structure(structure : Array(JSON::Any), base_path : String)
      structure.each do |item|
        item_hash = item.as_h
        name = item_hash["name"].as_s
        type = item_hash["type"].as_s
        item_path = File.join(base_path, name)

        # Skip .git directories to avoid permission issues
        if name == ".git"
          next
        end

        if type == "directory"
          begin
            Dir.mkdir_p(item_path) unless Dir.exists?(item_path)
            contents = item_hash["contents"]?.try(&.as_a) || [] of JSON::Any
            restore_structure(contents, item_path)
          rescue ex : File::AccessDeniedError
            # Skip directories we can't write to (like .git)
            next
          end
        else
          begin
            content = item_hash["content"].as_s
            File.write(item_path, Base64.decode_string(content))
          rescue ex : File::AccessDeniedError
            # Skip files we can't write to
            next
          end
        end
      end
    end

    private def restore_structure_with_progress(structure : Array(JSON::Any), base_path : String)
      structure.each do |item|
        item_hash = item.as_h
        name = item_hash["name"].as_s
        type = item_hash["type"].as_s
        item_path = File.join(base_path, name)

        # Skip .git directories to avoid permission issues
        if name == ".git"
          @current_item += 1
          update_progress
          next
        end

        if type == "directory"
          begin
            Dir.mkdir_p(item_path) unless Dir.exists?(item_path)
            contents = item_hash["contents"]?.try(&.as_a) || [] of JSON::Any
            restore_structure_with_progress(contents, item_path)
          rescue ex : File::AccessDeniedError
            # Skip directories we can't write to (like .git)
            @current_item += 1
            update_progress
            next
          end
        else
          begin
            content = item_hash["content"].as_s
            File.write(item_path, Base64.decode_string(content))
          rescue ex : File::AccessDeniedError
            # Skip files we can't write to
            @current_item += 1
            update_progress
            next
          end
        end

        @current_item += 1
        update_progress
      end
    end

    private def update_progress
      if callback = @progress_callback
        progress = @current_item.to_f32 / @total_items.to_f32
        callback.call(progress)
      end
    end
  end
end
