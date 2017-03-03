# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013-2017 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'pathname'
require 'java_buildpack/util'
require 'java_buildpack/util/jar_finder'
require 'java_buildpack/util/java_main_utils'

module JavaBuildpack
  module Util

    # Utilities for dealing with Payara Micro applications
    class PayaraMicroUtils

      def initialize
        @jar_finder = JavaBuildpack::Util::JarFinder.new(/.*payara-micro-([\d].*)\.jar/)
      end

      # Indicates whether an application is a Payara Micro application
      #
      # @param [Application] application the application to search
      # @return [Boolean] +true+ if the application is a Payara Micro application, +false+ otherwise
      def is?(application)
          @jar_finder.is?(application)
      end

      # The lib directory of Payara Micro used by the application
      #
      # @param [Droplet] droplet the droplet to search
      # @return [String] the lib directory of Payara Micro used by the application
      def lib(droplet)
        candidate = lib_dir(droplet)
        return candidate if candidate && candidate.exist?

        raise 'No lib directory found'
      end

      # The version of Payara Micro used by the application
      #
      # @param [Application] application the application to search
      # @return [String] the version of Payara Micro used by the application
      def version(application)
          @jar_finder.version(application)
      end

      private

      def lib_dir(droplet)
        droplet.root + 'lib'
      end

    end

  end
end