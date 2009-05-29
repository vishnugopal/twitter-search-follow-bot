
module TwitterPublicTimeline
  def self.included(base)
    base.class_eval do
      def public_timeline
        perform_get("/statuses/public_timeline.json")
      end
    end
  end
end

module Twitter
  class Base
    include TwitterPublicTimeline
  end
end