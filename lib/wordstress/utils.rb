module Wordstress
  class Utils

    # Transform a given URL into a directory name to be used to store data
    def target_to_dirname(target)
      target.split("://")[1].gsub('.','_').gsub('/', '')
    end

  end
end
