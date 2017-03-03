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

require 'java_buildpack/container'
require 'java_buildpack/container/dist_zip_like'
require 'java_buildpack/util/dash_case'
require 'java_buildpack/util/java_main_utils'
require 'java_buildpack/util/qualify_path'
require 'java_buildpack/util/payara_micro_utils'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for applications running a simple Java +main()+
    # method. This isn't a _container_ in the traditional sense, but contains the functionality to manage the lifecycle
    # of Java +main()+ applications.
    class PayaraMicro < JavaBuildpack::Component::BaseComponent
      include JavaBuildpack::Util

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        super(context)
        @payara_micro_utils = JavaBuildpack::Util::PayaraMicroUtils.new
      end

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def detect
        payara_script? ? PayaraMicro.to_s.dash_case : nil
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        (@droplet.root + 'bin/jq').chmod 0o755
        (@droplet.root + 'bin/payara-micro').chmod 0o755

        @droplet.additional_libraries.link_to(@payara_micro_utils.lib(@droplet))
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        manifest_class_path.each { |path| @droplet.additional_libraries << path }

        @droplet.additional_libraries.insert 0, @application.root

        classpath = @droplet.additional_libraries.as_classpath
        release_text(classpath)
      end

      private

      CLASS_PATH_PROPERTY = 'Class-Path'.freeze

      MAIN_CLASS = 'fish.payara.micro.PayaraMicro'.freeze

      private_constant :CLASS_PATH_PROPERTY, :MAIN_CLASS

      def release_text(classpath)
        [
          @droplet.java_opts.as_env_var,
          '&&',
          @droplet.environment_variables.as_env_vars,
          'exec',
          "bin/payara-micro",
          '&&',
          'eval',
          'exec',
          "#{qualify_path @droplet.java_home.root, @droplet.root}/bin/java",
          '$JAVA_OPTS',
          classpath,
          MAIN_CLASS,
          arguments
        ].flatten.compact.join(' ')
      end

      def arguments
        '--port $PORT --noCluster --deployment gluoncloudlink.war --domainConfig domain.xml'
      end

      def manifest_class_path
        values = JavaBuildpack::Util::JavaMainUtils.manifest(@application)[CLASS_PATH_PROPERTY]
        values.nil? ? [] : values.split(' ').map { |value| @droplet.root + value }
      end

      def payara_script?
        (@application.root + 'bin/payara-micro').exist?
      end

    end

  end
end
