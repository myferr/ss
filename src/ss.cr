require "option_parser"
require "./snapshot"
require "./snap_file"
require "./loader"

module Ss
  VERSION = "0.1.0"

  class CLI
    property id : String?
    property command : String?
    property target_dir : String?
    property preview : Bool
    property passphrase : String?

    def initialize
      @id = nil
      @command = nil
      @target_dir = nil
      @preview = false
      @passphrase = nil
    end

    def parse(args)
      OptionParser.parse(args) do |parser|
        parser.banner = <<-USAGE
        ss - snapshot your code .

        ss, or "snapshot", is a command line interface to save a state of your directory. this saved state acts as a snapshot for your code, allowed to be viewed, rolled back to, etc.

        Usage:
          ss snap <directory> | Snapshot a directory
          ss snap             | Snapshot your cwd
          ss list             | List your snapshots
          ss load <snapshot>  | Load a snapshot
          ss remove <snapshot> | Remove a snapshot

        Flags:
          --id                | Provide an ID for your snapshot
          --dir, -D           | Load snapshot to specific directory
          --preview, -p       | Preview snapshot contents
          --passphrase, -P    | Custom passphrase for encryption
        USAGE

        parser.on("--id VALUE", "Provide an ID for your snapshot") do |value|
          @id = value
        end

        parser.on("--dir VALUE", "-D", "Load snapshot to specific directory") do |value|
          @target_dir = value
        end

        parser.on("--preview", "-p", "Preview snapshot contents") do
          @preview = true
        end

        parser.on("--passphrase VALUE", "-P", "Custom passphrase for encryption") do |value|
          @passphrase = value
        end

        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit
        end

        parser.on("-v", "--version", "Show version") do
          puts "ss v#{VERSION}"
          exit
        end

        parser.unknown_args do |unknown_args|
          @command = unknown_args[0]?
        end
      end

      self
    end

    def run(args)
      parse(args)

      case @command
      when "snap"
        run_snap(args)
      when "list"
        run_list
      when "load"
        run_load(args)
      when "remove"
        run_remove(args)
      else
        run_snap(args)
      end
    end

    private def run_snap(args)
      directory = args[1]? || Dir.current
      snapshot = Snapshot.new(directory, @id, @passphrase)

      print "Snapshotting.. | "

      snapshot.set_progress_callback do |progress|
        print "\rSnapshotting.. | #{render_progress_bar(progress)} |"
      end

      filename = snapshot.save

      puts "\rSaved! View here: ~/.ss/#{filename}"
    end

    private def run_list
      home_dir = Path.home.to_s
      snapshots = Dir.glob(File.join(home_dir, ".ss", "*.snap"))

      if snapshots.empty?
        puts "you have 0 snapshots."
      else
        puts "you have #{snapshots.size} snapshots."
        puts ""
        snapshots.each do |snap|
          puts "- #{File.basename(snap)}"
        end
      end
    end

    private def run_load(args)
      snapshot = args[1]?

      unless snapshot
        puts "Error: Please specify a snapshot to load."
        puts "Use 'ss list' to see available snapshots."
        exit(1)
      end

      target = @target_dir || Dir.current
      confirm = @target_dir.nil?

      begin
        loader = Loader.new(snapshot, target, @passphrase)

        if @preview
          loader.preview
        else
          loader.set_progress_callback do |progress|
            print "\rLoading snapshot... | #{render_progress_bar(progress)} |"
          end

          loader.load_with_progress(confirm)
        end
      rescue ex
        exit(1)
      end
    end

    private def run_remove(args)
      snapshot = args[1]?

      unless snapshot
        puts "Error: Please specify a snapshot to remove."
        puts "Use 'ss list' to see available snapshots."
        exit(1)
      end

      home_dir = Path.home.to_s
      snapshot_path = File.join(home_dir, ".ss", snapshot)

      unless File.exists?(snapshot_path)
        puts "Error: Snapshot '#{snapshot}' not found."
        exit(1)
      end

      print "You sure you want to remove #{snapshot} (y/N)?: "
      input = gets

      if input && input.strip.downcase == "y"
        File.delete(snapshot_path)
        puts "Removed #{snapshot}"
      else
        puts "Cancelled."
      end
    end

    private def render_progress_bar(progress : Float32) : String
      filled = (progress * 10).to_i
      empty = 10 - filled

      "█" * filled + " " * empty
    end
  end
end

cli = Ss::CLI.new
cli.run(ARGV)
