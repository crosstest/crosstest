require 'celluloid'
# Common module to execute a Omnitest action such as create, converge, etc.

module Omnitest
  module RunAction
    class Worker
      include Celluloid

      def work(item, action, test_env_number, *args)
        item.vars['TEST_ENV_NUMBER'] = test_env_number if item.respond_to? :vars
        item.public_send(action, *args)
      rescue => e
        # Stop the error from propagating, return the error as a result.
        # This also prevents Celluloid actors from crashing.
        return e
      end
    end

    # Run an action on each member of the collection. The collection could
    # be Projects (e.g. clone, bootstrap) or Scenarios (e.g. test, clean).
    # The instance actions will take place in a seperate thread of execution
    # which may or may not be running concurrently.
    #
    # @param collection [Array] an array of objections on which to perform the action
    def run_action(collection, action, pool_size, *args)
      pool_size ||= 1
      pool_size = collection.size if pool_size > collection.size

      if pool_size > 1
        Celluloid::Actor[:omnitest_worker] = Worker.pool(size: pool_size)
      else
        Worker.supervise_as :omnitest_worker
      end

      # futures = collection.each_with_index.map do |item, index|
      collection.each_with_index.map do |item, index|
        actor = Celluloid::Actor[:omnitest_worker]
        actor.work(item, action, index, *args)
        # actor.future.work(item, action, index, *args)
      end
      # futures.map(&:value)
    end
  end
end
