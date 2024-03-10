require "test_helper"
require "minitest/autorun"
require "mocha/minitest"
require_relative "../../lib/subversion_repository.rb"

class SubversionRepositoryTest < Minitest::Test

  def setup
    @info_stub = {
      revision: "35",
      path: "brx",
      kind: "dir",
      url: "file:///var/repo/svn/example_repo/branches/brx",
      root: "file:///var/repo/svn/example_repo"
    }
    @log_stub = [
      {
        message: "merged",
        revision: "35"
      },
      {
        message: "refs #1241 #1242 fixed",
        revision: "33"
      },
      {
        message: "[refs #1234, #1235] add index1.html",
        revision: "32"
      }
    ]
    SubversionRepository.any_instance.stubs(:info).returns(@info_stub)
    SubversionRepository.any_instance.stubs(:log).returns(@log_stub)
    @ins = SubversionRepository.new(
      username: "user1",
      password: "pass1"
    ).uri("file:///var/repo/svn/example_repo/branches/brx/index1.html")

  end

  #def test_instance
  #  assert_equal SubversionRepository, @ins.class
  #end

  def test_root
      puts "#{@ins.info}"
      assert_equal "file:///var/repo/svn/example_repo", @ins.root
  end

  def test_is_branch
      assert @ins.is_branch?
  end
  
  def test_is_trunk
      assert @ins.is_trunk?.nil?
  end

  def test_path
      assert_equal @ins.path, "/branches/brx/index1.html"
  end
  
  def test_trunk
      assert_equal @ins.trunk, "file:///var/repo/svn/example_repo/trunk"
  end

  def test_repository_root
      assert_equal @ins.root,  "file:///var/repo/svn/example_repo"
  end

  def test_task_ids
        assert_equal @ins.task_ids, ["1241", "1242", "1234", "1235"]
  end
end

