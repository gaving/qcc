require 'rubygems'
require 'fileutils'
require 'date'
require 'win32ole'
require 'optparse'
require 'ostruct'
require 'yaml'
require 'pp'

class ParseOptions
    def self.parse(args)
        options = OpenStruct.new
        opts = OptionParser.new do |opts|
            opts.banner = "Usage: #{$0} [options]"
            opts.separator " "
            opts.separator "List options:"
            opts.on("--list-all", "All bugs") { |s| options.All = s }
            opts.separator "Statuses:"
            opts.on("--list-closed", "Closed bugs") { |s| options.Closed = s }
            opts.on("--list-fixed", "Fixed bugs") { |s| options.Fixed = s }
            opts.on("--list-open", "Open bugs") { |s| options.Open = s }
            opts.on("--list-reopen", "Reopen bugs") { |s| options.Reopen = s }
            opts.on("--list-new", "New bugs") { |s| options.New = s }
            opts.separator " "
            opts.separator "Filter options:"
            opts.on("-a", "--assigned-to", String, "Assigned to") { |s| options.list = s }
            opts.separator " "
            opts.separator "Action options:"
            opts.on("-c", "--mark-closed [BUG]", "Close bug") { |s| options.MClose = s }
            opts.on("-f", "--mark-fixed [BUG]", "Fixed bug") { |s| options.MFix = s }
            opts.on("-f", "--mark-new [BUG]", "New bug") { |s| options.MFix = s }
            opts.on("-f", "--mark-open [BUG]", "Open bug") { |s| options.MOpen = s }
            opts.separator " "
            opts.separator "Other options:"
            opts.on("-i", "--info [BUG]", "Show info about bug") { |s| options.info = s }
            opts.on("-i", "--comment [BUG]",  "Show info about bug") { |s| options.comment = s }
            opts.separator " "
            opts.separator "Output options:"
            opts.separator " "
            opts.separator "Common options:"
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

options = ParseOptions.parse(ARGV)

has_list = %w[All Closed Fixed Open Reopen New].any?{ |param| !options.send(param).nil? }
has_action = %w[MClose MFix MNew MOpen].any?{ |param| !options.send(param).nil? }

unless has_list || has_action
    $stderr.puts "Error: you must specify a list option or action"
    exit 1
end

yml = YAML::load(File.open(File.dirname(__FILE__) + '/config.yml'))

qc = WIN32OLE.new('TDApiOle80.TDConnection')
qc.InitConnectionEx(yml['config']['uri'])
qc.login(yml['config']['username'], yml['config']['password'])
qc.Connect(yml['config']['domain'], yml['config']['project'])

bf = qc.BugFactory
bfi = bf.Filter

if has_list
    status = %w[Closed Fixed Open Reopen New].select{ |param| !options.send(param).nil? || !options.send('All').nil? }.join(' Or ')
    bfi.setproperty('Filter', 'BG_STATUS', status)

    bf.NewList(bfi.Text).each do |value|
        puts "%s|%s|%s|%s|%s" % [value.Id, value.Status, value.DetectedBy, value.AssignedTo, value.Summary]
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
            puts "Defect #{bug_no} marked to #{status}."
        end
    end
end
