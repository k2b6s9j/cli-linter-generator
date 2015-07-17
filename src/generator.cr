require "ecr/macros"
require "colorize"

module Linter
  module Generator
    TEMPLATE_DIR = "#{__DIR__}/template"

    class Config
      macro property_without_newline(property_name)
        property {{property_name.id}}

        def {{property_name.id}}=({{property_name.id}})
          @{{property_name.id}} = {{property_name.id}}.to_s.chomp("\n")
        end
      end

      property_without_newline name
      property_without_newline version
      property_without_newline command
      property_without_newline scopes
      property_without_newline regex
      property_without_newline owner
      property silent

      def initialize
        @name = "linter-echo"
        @version = "0.0.0"
        @command = "echo"
        @scopes = "*"
        @regex = "(.+)"
        @owner = "AtomLinter"
        @silent = false
      end

      def scopes
        scopes = @scopes.to_s.split(", ")
      end

      def arguments
        args = @command.to_s.split(" ")
        args - [args[0]]
      end
    end

    abstract class View
      getter config

      @@views = [] of View.class

      def self.views
        @@views
      end

      def self.register(view)
        views << view
      end

      def initialize(@config)
      end

      def render
        Dir.mkdir_p(File.dirname(full_path))
        File.write(full_path, to_s)
        puts log_message unless config.silent
      end

      def log_message
        "      #{"create".colorize(:light_green)}  #{full_path}"
      end

      abstract def full_path
    end

    class InitProject
      getter config

      def initialize(@config)
      end

      def run
        views.each do |view|
          view.new(config).render
        end
      end

      def views
        View.views
      end
    end

    macro template(name, template_path, full_path)
      class {{name.id}} < View
        ecr_file "{{TEMPLATE_DIR.id}}/{{template_path.id}}"
        def full_path
          "output/#{{{full_path}}}"
        end
      end

      View.register({{name.id}})
    end

    template MainJavaScriptView, "main.js.ecr", "lib/main.js"
    template ProjectJsonView, "project.json.ecr", "project.json"
  end
end

config = Linter::Generator::Config.new

puts "Linter Name:".colorize.bold
config.name = gets
puts "Linter Version:".colorize.bold
config.version = gets
puts "Linter Command:".colorize.bold
config.command = gets
puts "Linter Scopes:".colorize.bold
config.scopes = gets
puts "Linter Regex:".colorize.bold
config.regex = gets
puts "Linter Repo Owner:".colorize.bold
config.owner = gets

puts ""

puts "Beginning Creation of #{config.name}".colorize(:green).bold

Linter::Generator::InitProject.new(config).run

puts "Creation of #{config.name} Finished".colorize(:green).bold
