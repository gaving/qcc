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
    HTMLEntities.new.decode(self.gsub(/(.{1,100})( +|$\n?)|(.{1,100})/, "\\1\\3\n"))
  end
  def trunca(length=100, ellipsis='...')
    self.length > length ? self[0..length].gsub(/\s*\S*\z/, '').rstrip+ellipsis : self.rstrip
  end
  def repeat(n=1)
    self * n
  end
end

module QCC

  class ParseOptions
    def self.parse(args)
      options = OpenStruct.new
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"
        opts.separator " "
        opts.separator "List:"
        opts.on("--list-all", "All defects") { |s| options.All = s }
        opts.on("--list-closed", "Closed defects") { |s| options.Closed = s }
        opts.on("--list-fixed", "Fixed defects") { |s| options.Fixed = s }
        opts.on("--list-open", "Open defects") { |s| options.Open = s }
        opts.on("--list-reopen", "Reopen defects") { |s| options.Reopen = s }
        opts.on("--list-new", "New defects") { |s| options.New = s }
        opts.on("--list-rejected", "Rejected defects") { |s| options.Rejected = s }
        opts.separator " "
        opts.separator "Assigned:"
        opts.on("--assigned [USER1,USER2,...]", "Assigned to user") { |s| options.assigned = s }
        opts.separator " "
        opts.separator "Search:"
        opts.on("--search [PATTERN]", "Search defect summary for pattern") { |s| options.search = s }
        opts.separator " "
        opts.separator "Action:"
        opts.on("-c", "--mark-closed [DEFECT]", "Close defect") { |s| options.MClose = s }
        opts.on("-f", "--mark-fixed [DEFECT]", "Fixed defect") { |s| options.MFix = s }
        opts.on("-n", "--mark-new [DEFECT]", "New defect") { |s| options.MFix = s }
        opts.on("-o", "--mark-open [DEFECT]", "Open defect") { |s| options.MOpen = s }
        opts.on("-r", "--mark-rejected [DEFECT]", "Reject defect") { |s| options.MReject = s }
        opts.separator " "
        opts.separator "Other:"
        opts.on("-i", "--info [DEFECT]", "Show info about defect") { |s| options.info = s }
        opts.on("-d", "--download", "Download the attachments when viewing defect info") { |s| options.download = s }
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        opts.on_tail("--version", "Show version") do
          puts VERSION
          exit
        end
      end.parse!(args)
      options
    end
  end

  def self.qcc!
    options = ParseOptions.parse(ARGV)

    has_list = %w[All Closed Fixed Open Reopen New Rejected].any?{ |param| !options.send(param).nil? }
    has_action = %w[MClose MFix MNew MOpen MReject].any?{ |param| !options.send(param).nil? }
    has_info = !options.info.nil?
    has_assigned = !options.assigned.nil?
    has_search = !options.search.nil?

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
      status = %w[
        Closed
        Fixed
        Open
        Reopen
        New
        Rejected
      ].select do |param|
        !options.send(param).nil? || !options.send('All').nil?
      end.join(' Or ')

      if has_assigned
        assigned = options.assigned.split(',')
      end

      if has_search
        bfi.setproperty('Filter', 'BG_SUMMARY', "*#{options.search}*")
      end

      bfi.setproperty('Filter', 'BG_STATUS', status)

      begin
        defect_table = table do
          self.headings = 'Id', 'Priority', 'Status', 'Detected By', 'Assigned To', 'Summary'
          bf.NewList(bfi.Text).each do |value|
            unless has_assigned and !assigned.include?(value.AssignedTo)
              add_row [value.Id, value.Priority, value.Status, value.DetectedBy, value.AssignedTo, value.Summary.trunca]
            end
          end
          align_column 1, :center
        end

        puts defect_table
      rescue Terminal::Table::Error
        puts "No defects to display".yellow
      end
    end

    if has_info
      bfi.setproperty('Filter', 'BG_BUG_ID', options.info)
      bf.NewList(bfi.Text).each do |value|
        puts "%s".green % [value.Summary.wrap]

        begin
          defect_table = table do
            self.headings = 'Id', 'Priority', 'Status', 'Detected By', 'Assigned To'
            add_row [value.Id, value.Priority, value.Status, value.DetectedBy, value.AssignedTo]
            align_column 1, :center
          end

          puts defect_table
        rescue Terminal::Table::Error
          puts "No defects to display".yellow
        end

        puts '_'.repeat(50)

        %w[BG_DESCRIPTION BG_DEV_COMMENTS].each do |desc|
          unless value.Field(desc).nil?
            puts value.Field(desc).gsub!('_'.repeat(40), "\r\n" + '_'.repeat(50) + "\r\n").to_s.strip.wrap.blue
          end
        end

        if !options.download.nil?
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
    end

    if has_action
      statuses = {
        'MClose' => 'Closed',
        'MFix' => 'Fixed',
        'MNew' => 'New',
        'MOpen' => 'Open',
        'MReject' => 'Rejected'
      }

      %w[
        MClose
        MFix
        MNew
        MOpen
        MReject
      ].select{ |param| !options.send(param).nil? }.each do |param|
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

    qc.Disconnect
    qc.Logout
    qc.ReleaseConnection
  end
end
