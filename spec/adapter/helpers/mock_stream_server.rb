module Paasal
  # Copied from the rack-stream project at https://github.com/intridea/rack-stream
  #
  # Copyright (c) 2012, Jerry Cheung
  # All rights reserved.
  #
  # Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
  # following conditions are met:
  # Redistributions of source code must retain the above copyright notice, this list of conditions and the following
  # disclaimer.
  #
  # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
  # INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  # DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  # SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
  # WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
  # USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  #
  class MockStreamServer
    class Callback
      attr_reader :status, :headers, :body

      def initialize(&blk)
        @succeed_callback = blk
      end

      def call(args)
        @status, @headers, deferred_body = args
        @body = []
        deferred_body.each do |s|
          @body << s
        end
        deferred_body.callback { @succeed_callback.call }
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      f = Fiber.current
      callback = Callback.new do
        f.resume [callback.status, callback.headers, callback.body]
      end
      env['async.callback'] = callback
      @app.call(env)
      Fiber.yield # wait until deferred body is succeeded
    end
  end
end
