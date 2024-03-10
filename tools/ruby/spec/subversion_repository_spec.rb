require 'spec_helper'

describe 'info' do

  before do
    @ins = SubversionRepository.new(
      username: "user1",
      password: "pass1"
    ).uri("file:///var/repo/svn/example_repo/branches/brx/index1.html")

    allow(@ins).to receive(:info) do
      {
        revision: "35",
        path: "brx",
        kind: "dir",
        url: "file:///var/repo/svn/example_repo/branches/brx",
        root: "file:///var/repo/svn/example_repo"
      }
    end

    allow(@ins).to receive(:commit_logs) do
      [
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
    end
  end

  it "new instance" do
    expect(@ins.class).to eq(SubversionRepository)
  end

  it "is branch" do
    expect(@ins.is_branch?).to be_truthy
  end
  
  it "is not trunk" do
    expect(@ins.is_trunk?).to be_falsey
  end

  it "path" do
    expect(@ins.path).to eq("/branches/brx/index1.html")
  end
  
  it "trunk" do
    expect(@ins.trunk).to eq("file:///var/repo/svn/example_repo/trunk")
  end

  it "repository root" do
    expect(@ins.root).to eq("file:///var/repo/svn/example_repo")
  end

  it "task_ids" do
    expect(@ins.task_ids).to eq(["1241", "1242", "1234", "1235"])
  end
end
