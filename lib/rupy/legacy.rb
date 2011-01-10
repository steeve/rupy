require 'rupy'

module Rupy::LegacyMode
    class << self
        def setup_legacy
            Rupy.legacy_mode = true
        end

        def teardown_legacy
            Rupy.legacy_mode = false
        end
    end
end

Rupy::LegacyMode.setup_legacy
