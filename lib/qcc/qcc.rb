require "qcc/version"

require 'rubygems'
require 'fileutils'
require 'date'
require 'win32ole'
require 'optparse'
require 'ostruct'
require 'yaml'

require 'htmlentities'
require 'terminal-table/import'

class String
    def red; colorize(self, "\e[1m\e[31m"); end
    def green; colorize(self, "\e[1m\e[32m"); end
    def dark_green; colorize(self, "\e[32m"); end
    def yellow; colorize(self, "\e[1m\e[33m"); end
    def blue; colorize(self, "\e[1m\e[34m"); end
    def dark_blue; colorize(self, "\e[34m"); end
    def pur; colorize(self, "\e[1m\e[35m"); end
    def colorize(text, color_code) "#{color_code}#{text}\e[0m" end
    def strip
        self.gsub(/<br>/,"\r\n").gsub( %r{</?[^>]+?>}, '' )
    end
    def wrap
        return HTMLEntities.new.decode(self.gsub(/(.{1,100})( +|$\n?)|(.{1,100})/, "\\1\\3\n"))
    end
end

module QCC

    class ParseOptions
        def self.parse(args)
            options = OpenStruct.new
            opts = OptionParser.new do |opts|
                opts.banner = "Usage: #{$0} [options]"
                opts.separator " "
                opts.separator "List options:"
                opts.on("--list-all", "All bugs") { |s| options.All = s }
                opts.on("--list-closed", "Closed bugs") { |s| options.Closed = s }
                opts.on("--list-fixed", "Fixed bugs") { |s| options.Fixed = s }
                opts.on("--list-open", "Open bugs") { |s| options.Open = s }
                opts.on("--list-reopen", "Reopen bugs") { |s| options.Reopen = s }
                opts.on("--list-new", "New bugs") { |s| options.New = s }
                opts.separator " "
                opts.separator "Action options:"
                opts.on("-c", "--mark-closed [BUG]", "Close bug") { |s| options.MClose = s }
                opts.on("-f", "--mark-fixed [BUG]", "Fixed bug") { |s| options.MFix = s }
                opts.on("-n", "--mark-new [BUG]", "New bug") { |s| options.MFix = s }
                opts.on("-o", "--mark-open [BUG]", "Open bug") { |s| options.MOpen = s }
                opts.separator " "
                opts.separator "Other options:"
                opts.on("-i", "--info [BUG]", "Show info about bug") { |s| options.info = s }
                opts.on_tail("-h", "--help", "Show this message") do
                    puts opts
                    exit
                end
                opts.on_tail("--version", "Show version") do
                    puts PVERSION
                    exit
                end
            end
            opts.parse!(args)
            options
        end
    end

    def self.qcc!

        options = ParseOptions.parse(ARGV)

        has_list = %w[All Closed Fixed Open Reopen New].any?{ |param| !options.send(param).nil? }
        has_action = %w[MClose MFix MNew MOpen].any?{ |param| !options.send(param).nil? }
        has_info = !options.info.nil?

        unless has_list || has_action || has_info
            $stderr.puts "Error: you must specify a --list option, --mark or --info"
            exit 1
        end

        begin
            file = File.join(File.expand_path('~'), '.qccrc')
            yml = YAML::load(File.open(file))
            qc = WIN32OLE.new('TDApiOle80.TDConnection')
            qc.InitConnectionEx(yml['config']['uri'])
            qc.login(yml['config']['username'], yml['config']['password'])
            qc.Connect(yml['config']['domain'], yml['config']['project'])
        rescue Errno::ENOENT
            puts "qcc: #{file}: No such file or directory"
            exit 1
        rescue Errno::EACCES
            puts "qcc: #{file}: Permission denied"
            exit 1
        rescue Errno::EISDIR
            puts "qcc: #{file}: Is a directory"
            exit 1
        rescue Errno::EPIPE
            exit 1
        end

        bf = qc.BugFactory
        bfi = bf.Filter

        if has_list
            status = %w[Closed Fixed Open Reopen New].select{ |param| !options.send(param).nil? || !options.send('All').nil? }.join(' Or ')
            bfi.setproperty('Filter', 'BG_STATUS', status)

            defect_table = table do
                self.headings = 'Id', 'Status', 'Detected By', 'Assigned To', 'Summary'
                bf.NewList(bfi.Text).each do |value|
                    add_row [value.Id, value.Status, value.DetectedBy, value.AssignedTo, value.Summary]
                end
                align_column 1, :center
            end

            puts defect_table
        end

        if has_info
            bfi.setproperty('Filter', 'BG_BUG_ID', options.info)
            bf.NewList(bfi.Text).each do |value|
                puts "%s - %s".green % [value.Id, value.Summary]
                puts "Detected by: %s".yellow % value.DetectedBy
                puts "Assigned to: %s".yellow % value.AssignedTo
                puts "Status: %s\r\n".yellow % value.Status
                %w[BG_DESCRIPTION BG_DEV_COMMENTS].each do |desc|
                    puts value.Field(desc).strip.wrap.blue unless value.Field(desc).nil?
                end
                value.Attachments.NewList('').each do |attachment|
                    #p attachment.Name, attachment.Description
                    #p attachment.ServerFileName
                    #p attachment.AttachmentStorage
                    #p attachment.FileName

                    file = attachment.AttachmentStorage
                    file.ClientPath = yml['config']['download_directory']
                    file.Load attachment.Name, true
                    puts "Saved: %s\r\n".red % attachment.FileName
                end
            end
        end

        if has_action
            statuses = { 'MClose' => 'Closed', 'MFix' => 'Fixed', 'MNew' => 'New', 'MOpen' => 'Open' }
            %w[MClose MFix MNew MOpen].select{ |param| !options.send(param).nil? }.each do |param|
                bug_no = options.send(param);
                status = statuses[param]
                bfi.setproperty('Filter', 'BG_BUG_ID', bug_no)
                bf.NewList(bfi.Text).each do |value|
                    value.setproperty('Status', status)
                    value.Post
                    puts "Defect #{bug_no} marked to #{status}.".green
                end
            end
        end
    end
end
