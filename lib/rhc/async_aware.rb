#
# Prototype support for simple parallel requests.  It is the callers
# responsibility to ensure that blocks are side-effect free.
#
module AsyncAware

  def async(&block)
    (@threads ||= []) << Thread.start do
      begin
        Thread.current[:out] = yield block
      rescue => e
        Thread.current[:out] = e
      end
    end
  end

  def join(limit=nil)
    running = @threads
    t1 = Time.now.to_i

    threads = begin
                @threads.map{ |t| limit ? t.join(limit) : t.join }
              ensure
                @threads.each(&:kill)
                @threads = nil
              end

    #puts                  "**** Joined #{Time.now.to_i - t1} (limit=#{limit})"
    #puts running.map{ |t| "     #{t.inspect}: #{threads.include?(t) ? "" : "(did not finish) "}#{t[:out].inspect}" }.join("\n")

    running.map do |t| 
      if threads.include?(t) 
        t[:out]
      else
        begin; raise(ThreadTimedOut.new(t, limit)); rescue => e; e; end
      end
    end
  end

  #
  # Throw the first exception encountered
  #
  def join!(limit=nil)
    join(limit).tap do |results|
      exceptions = results.select{ |r| r.is_a? StandardError }
      exceptions[1..-1].each{ |e| error "#{e.class} (#{e})\n  #{e.backtrace.join("\n  ")}" } if exceptions.size > 1
      raise exceptions.first unless exceptions.empty?
    end
  end

  def prefetch(&block)
    (response = yield).tap do |objs|
      [*objs].each do |obj|
        async{ obj.prefetch }
      end
      join!(30)
    end
  end

  class ThreadTimedOut < StandardError
    attr_reader :thread
    def initialize(thread, timeout)
      @thread, @timeout = thread, timeout
    end
    def to_s
      "The thread #{thread.inspect} did not complete within #{@timeout} seconds."
    end
  end
end
