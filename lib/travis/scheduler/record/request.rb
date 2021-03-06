require 'active_record'
require 'travis/scheduler/record/organization'
require 'travis/scheduler/record/repository'
require 'travis/scheduler/record/user'
require 'gh'

class Request < ActiveRecord::Base
  belongs_to :commit
  belongs_to :repository
  belongs_to :owner, polymorphic: true

  serialize :payload

  # this method is overly long, but please don't refactor it just to shorten it,
  # I want it to be as clear as possible as any bug here can lead to security
  # issues
  def same_repo_pull_request?
    payload = Hashr.new(self.payload)

    pull_request = payload.pull_request
    return false unless pull_request

    head = pull_request.head
    base = pull_request.base
    return false if head.nil? or base.nil?

    base_repo = base.repo.try(:full_name)
    head_repo = head.repo.try(:full_name)
    return false if base_repo.nil? or base_repo.nil?
    return false if head.sha.nil? or head.ref.nil?

    # it's not the same repo PR if repo names don't match
    return false if head_repo != base_repo

    # it may not be same repo PR if ref is a commit
    return false if head.sha =~ /^#{Regexp.escape(head.ref)}/

    true
  rescue => e
    Travis::Scheduler.logger.error "[request:#{id}] Couldn't determine whether pull request is from the same repository: #{e.message}"
    false
  end
end
