#! /usr/bin/env ruby

class SubversionRepository
  require "rexml/document"

  def initialize(auth = {})
    @username = auth[:username] || ""
    @password = auth[:password] || ""
    @uri = ""
    @info = {}
  end

  def uri(uri = "")
    @uri = uri.sub /\/$/, ""
    @info = {}
    self
  end

  def path
    @uri.sub(root(), "")
  end

  def repository
    (root().split "/").pop
  end

  def trunk
    root() + "/trunk"
  end

  def info
    return @info unless @info.empty?
    @info = {}
    code = 0
    path_parts = @uri.split /\//
    while(path_parts.pop)
      svn_path = path_parts.join "/"
      info_command(svn_path) do |io|
        code = $?.to_i
        next info if code != 0
        received = io.read
        @info = parse_info(received)
      end
      break unless @info.empty?
    end
    @info
  end

  def log(uri = @uri)
    logs = []
    code = 0
    log_command(uri) do |io|
      code = $?.to_i
      return logs if code != 0
      received = io.read
      logs = parse_log(received)
    end
    logs
  end

  def root()
    info()[:root]
  end

  def is_trunk?
    path() =~ /^\/trunk/
  end

  def is_branch?
    path() =~ /^\/branches/
  end

  def file_path
    if is_trunk?
      path().sub /^\/trunk\/.+?\//, ""
    elsif is_branch?
      path().sub /^\/branches\/.+?\//, ""
    else
      path()
    end
  end

  #
  # trunkに同名ファイルがあればtrunkのファイルパス
  # 無ければ現在のファイルパス
  # 現在のファイルも無ければ空文字を返す
  #
  def active_file_path
    path = file_path()
    res = log(root() + "/trunk/" + path)
    return "/trunk/" + path unless res.empty?
    res = log()
    return @uri unless res.empty?
    ""
  end

  def commit_logs()
    logs = []
    path = active_file_path()
    return logs if path.empty?
    log(root() + path).each do |line|
      logs << {
        message: line[:message].strip,
        revision: line[:revision],
      }
    end
    logs
  end

  def to_parent
    return self if @uri.size <= root().size
    parts = @uri.split "/"
    parts.pop
    @uri = parts.join "/"
    self
  end

  #---------#
  # svn log #
  #---------#
  #
  # [
  #   {
  #     author: "author1",
  #     revision: 12233,
  #     datetime: "2021-07-31T23:30:30",
  #     message: "[refs #134,#135] msg1",
  #     paths: {
  #       action: "{"A" || "D" || "M"}",
  #       file:   "{filepath}"
  #     }
  #   },
  #   ...
  # ]
  #
  protected def parse_log(xml_body)
    lines = []
    begin
      doc = REXML::Document.new(xml_body)
    rescue
      return lines
    end
    REXML::XPath.match(doc, "/log/logentry").each do |entry|
      line = {
        author:   entry.elements["author"].text,
        revision: entry.attribute("revision").value,
        datetime: entry.elements["date"].text,
        message:  entry.elements["msg"].text,
        paths:   []
      }
      REXML::XPath.match(entry, "paths/path").each do |path|
        attrs = {}
        attrs[:path] = path.text
        %i(action copyfrom-path).each do |sym|
          attrs[sym] = path.attribute(sym.to_s).value if path.attribute(sym.to_s)
        end
        line[:paths] << attrs
      end
      lines << line
    end
    lines
  end

  protected def log_command(path)
    IO.popen("svn log --xml -v --username #{@username} --password #{@password} #{path}", "r") do |io|
      yield(io)
    end
  end

  #----------#
  # svn info #
  #----------#
  #
  protected def parse_info(xml_body)
    info = {}
    begin
      doc = REXML::Document.new(xml_body)
    rescue
      return info
    end
    #repository = REXML::XPath.match(doc, "/info/entry/repository")
    REXML::XPath.match(doc, "/info/entry").each do |entry|
      info[:revision] = entry.attribute("revision").value
      info[:path] = entry.attribute("path").value
      info[:kind] = entry.attribute("kind").value
      info[:url]  = entry.elements["url"].text
      REXML::XPath.match(entry, "repository").each do |repository|
        info[:root] = repository.elements["root"].text
      end
    end
    info
  end

  protected def info_command(path)
    IO.popen("svn info --xml --username #{@username} --password #{@password} #{path}", "r") do |io|
      yield(io)
    end
  end

  #------#
  # refs #
  #------#
  def parse_refs(message)
    return [] unless message || message !~ /refs/
    message.scan /(?<=#)\d+/
  end

  def task_ids
    task_ids = []
    lines = commit_logs()
    lines.each do |line|
      issue_ids = parse_refs(line[:message])
      next if issue_ids.empty?
      task_ids.concat issue_ids
    end
    task_ids
  end
end

#
# how2use
#
#uri = "file:///var/repo/svn/tesuto/branches/brx/index1.html"
#svn = SubversionRepository.new(username: "user1", password: "pass1").uri(uri)
#puts svn.task_ids()



