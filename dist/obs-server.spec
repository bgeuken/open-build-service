#
# spec file for package obs-server
#
# Copyright (c) 2018 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


%if 0%{?fedora}
%global sbin /usr/sbin
%else
%global sbin /sbin
%endif

%if 0%{?fedora} || 0%{?rhel}
%global apache_user apache
%global apache_group apache
%else
%global apache_user wwwrun
%global apache_group www
%endif

%define secret_key_file /srv/www/obs/api/config/secret.key

%if ! %{defined _fillupdir}
  %define _fillupdir %{_localstatedir}/adm/fillup-templates
%endif

%if 0%{?suse_version} >= 1315
%define reload_on_update() %{?nil:
	test -n "$FIRST_ARG" || FIRST_ARG=$1
	if test "$FIRST_ARG" -ge 1 ; then
	   test -f /etc/sysconfig/services && . /etc/sysconfig/services
	   if test "$YAST_IS_RUNNING" != "instsys" -a "$DISABLE_RESTART_ON_UPDATE" != yes ; then
	      test -x /bin/systemctl && /bin/systemctl daemon-reload >/dev/null 2>&1 || :
	      for service in %{?*} ; do
		 test -x /bin/systemctl && /bin/systemctl reload $service >/dev/null 2>&1 || :
	      done
	   fi
	fi
	%nil
}
%endif

Name:           obs-server
Summary:        The Open Build Service -- Server Component
License:        GPL-2.0 and GPL-3.0
%if 0%{?suse_version} < 1210 && 0%{?suse_version:1}
Group:          Productivity/Networking/Web/Utilities
%endif
Version:        2.10~pre
Release:        0
Url:            http://www.openbuildservice.org
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        open-build-service-%version.tar.xz
BuildRequires:  python-devel
# needed for native extensions
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  gcc
BuildRequires:  cyrus-sasl-devel
BuildRequires:  glibc-devel
BuildRequires:  libtool
BuildRequires:  libxml2-devel
BuildRequires:  libxslt-devel
BuildRequires:  make
BuildRequires:  mysql-devel
BuildRequires:  nodejs
BuildRequires:  openldap2-devel
BuildRequires:  ruby2.5-devel
BuildRequires:  phantomjs
# make sure this is in sync with the RAILS_GEM_VERSION specified in the
# config/environment.rb of the various applications.
# atm the obs rails version patch above unifies that setting among the applications
# also see requires in the obs-server-api sub package
BuildRequires:  build >= 20170315
BuildRequires:  inst-source-utils
BuildRequires:  perl-BSSolv >= 0.28
BuildRequires:  perl-Compress-Zlib
BuildRequires:  perl-Diff-LibXDiff
BuildRequires:  perl-File-Sync >= 0.10
BuildRequires:  perl-JSON-XS
BuildRequires:  perl-Net-SSLeay
BuildRequires:  perl-Socket-MsgHdr
BuildRequires:  perl-TimeDate
BuildRequires:  perl-XML-Parser
BuildRequires:  perl-XML-Simple
BuildRequires:  perl(Devel::Cover)
BuildRequires:  perl(Test::Simple) > 1
BuildRequires:  procps
# Required by the test suite (contains /usr/bin/Xvfb)
BuildRequires:  xorg-x11-server
PreReq:         /usr/sbin/useradd /usr/sbin/groupadd
Requires(pre):  obs-common
Requires:       build >= 20170315
Requires:       perl-BSSolv >= 0.28
Requires:       perl(Date::Parse)
# Required by source server
Requires:       diffutils
PreReq:         git-core
Requires:       patch
# require the createrepo and python-yum version which got validated during testsuite run
%if 0%{?suse_version} < 1500
Requires:       %(/bin/bash -c 'rpm -q --qf "%%{name} = %%{version}-%%{release}" createrepo')
Requires:       %(/bin/bash -c 'rpm -q --qf "%%{name} = %%{version}-%%{release}" python-yum')
%else
Requires:       /usr/bin/createrepo
%endif
Recommends:     cron logrotate

Obsoletes:      obs-devel
Provides:       obs-devel

BuildRequires:  xz

%if 0%{?suse_version:1}
BuildRequires:  fdupes
PreReq:         %insserv_prereq permissions pwdutils
%endif

%if 0%{?suse_version:1}
Recommends:     yum yum-metadata-parser repoview dpkg
Recommends:     deb >= 1.5
Recommends:     lvm2
Recommends:     openslp-server
Recommends:     obs-signd
Recommends:     inst-source-utils
Recommends:     perl-Diff-LibXDiff
%else
Requires:       dpkg
Requires:       yum
Requires:       yum-metadata-parser
%endif
Requires:       perl-Compress-Zlib
Requires:       perl-File-Sync >= 0.10
Requires:       perl-JSON-XS
Requires:       perl-Net-SSLeay
Requires:       perl-Socket-MsgHdr
Requires:       perl-XML-Parser
Requires:       perl-XML-Simple

Obsoletes:	obs-source_service < 2.9
Obsoletes:	obs-productconverter < 2.9
Provides:	obs-source_service = %version
Provides:	obs-productconverter = %version

Recommends:     obs-service-download_url
Recommends:     obs-service-verify_file

%if 0%{?suse_version} >= 1210
BuildRequires: systemd-rpm-macros
%endif

%{?systemd_requires}

%description
The Open Build Service (OBS) backend is used to store all sources and binaries. It also
calculates the need for new build jobs and distributes it.

%package -n obs-worker
Requires(pre):  obs-common
Requires:       cpio
Requires:       curl
Requires:       perl-Compress-Zlib
Requires:       perl-TimeDate
Requires:       perl-XML-Parser
Requires:       screen
# for build script
Requires:       psmisc
# For runlevel script:
Requires:       curl
Recommends:     openslp lvm2
Requires:       bash
Requires:       binutils
Requires:       bsdtar
Summary:        The Open Build Service -- Build Host Component
%if 0%{?suse_version} && 0%{?suse_version} < 1210
Group:          Productivity/Networking/Web/Utilities
%endif
%if 0%{?suse_version}
PreReq:         %insserv_prereq
%endif
%if 0%{?suse_version} <= 1030
Requires:       lzma
%endif
Requires:       util-linux >= 2.16
# the following may not even exist depending on the architecture
Recommends:     powerpc32

%description -n obs-worker
This is the obs build host, to be installed on each machine building
packages in this obs installation.  Install it alongside obs-server to
run a local playground test installation.

%package -n obs-common
Summary:        The Open Build Service -- base configuration files
Requires(pre):  shadow
%if 0%{?suse_version} && 0%{?suse_version} < 1210
Group:          Productivity/Networking/Web/Utilities
%endif
%if 0%{?suse_version}
PreReq:         %fillup_prereq
%endif

%description -n obs-common
This is a package providing basic configuration files.

%package -n obs-api
Summary:        The Open Build Service -- The API and WEBUI
%if 0%{?suse_version} && 0%{?suse_version} < 1210
Group:          Productivity/Networking/Web/Utilities
%endif
%if 0%{?suse_version}
PreReq:         %insserv_prereq
Requires(pre):  obs-common
%endif
%if 0%{?suse_version} >= 1330
Requires(pre):  group(www)
%endif

#For apache
Requires:       apache2 apache2-mod_xforward rubygem-passenger-apache2 ruby2.5-rubygem-passenger

# memcache is required for session data
Requires:       memcached
Conflicts:      memcached < 1.4

Requires:       mysql

Requires:       ruby(abi) >= 2.0
# needed for fulltext searching
Requires:       sphinx >= 2.1.8
BuildRequires:       sphinx >= 2.1.8
BuildRequires:  rubygem(ruby-ldap)
# For doc generation
BuildRequires:  rubygem(i18n)
# for test suite:
BuildRequires:  createrepo
BuildRequires:  curl
BuildRequires:  memcached >= 1.4
BuildRequires:  mysql
BuildRequires:  netcfg
BuildRequires:  xorg-x11-Xvnc
BuildRequires:  xorg-x11-server
BuildRequires:  xorg-x11-server-extra
# write down dependencies for production
BuildRequires:  rubygem(bundler)
Source1:        obs-server-rpmlintrc
Source2:        Gemfile
Source3:        Gemfile.lock
### GEMS START
Source100:      https://rubygems.org/downloads/actioncable-5.1.5.gem
Source101:      https://rubygems.org/downloads/actionmailer-5.1.5.gem
Source102:      https://rubygems.org/downloads/actionpack-5.1.5.gem
Source103:      https://rubygems.org/downloads/actionview-5.1.5.gem
Source104:      https://rubygems.org/downloads/activejob-5.1.5.gem
Source105:      https://rubygems.org/downloads/activemodel-5.1.5.gem
Source106:      https://rubygems.org/downloads/activemodel-serializers-xml-1.0.2.gem
Source107:      https://rubygems.org/downloads/activerecord-5.1.5.gem
Source108:      https://rubygems.org/downloads/activesupport-5.1.5.gem
Source109:      https://rubygems.org/downloads/acts_as_list-0.9.10.gem
Source110:      https://rubygems.org/downloads/acts_as_tree-2.7.0.gem
Source111:      https://rubygems.org/downloads/addressable-2.5.2.gem
Source112:      https://rubygems.org/downloads/airbrake-7.1.0.gem
Source113:      https://rubygems.org/downloads/airbrake-ruby-2.5.0.gem
Source114:      https://rubygems.org/downloads/amq-protocol-2.3.0.gem
Source115:      https://rubygems.org/downloads/annotate-2.7.2.gem
Source116:      https://rubygems.org/downloads/ansi-1.5.0.gem
Source117:      https://rubygems.org/downloads/arel-8.0.0.gem
Source118:      https://rubygems.org/downloads/ast-2.4.0.gem
Source119:      https://rubygems.org/downloads/bcrypt-3.1.11.gem
Source120:      https://rubygems.org/downloads/builder-3.2.3.gem
Source121:      https://rubygems.org/downloads/bullet-5.7.3.gem
Source122:      https://rubygems.org/downloads/bunny-2.9.2.gem
Source123:      https://rubygems.org/downloads/capybara-2.18.0.gem
Source124:      https://rubygems.org/downloads/capybara_minitest_spec-1.0.6.gem
Source125:      https://rubygems.org/downloads/chunky_png-1.3.10.gem
Source126:      https://rubygems.org/downloads/cliver-0.3.2.gem
Source127:      https://rubygems.org/downloads/clockwork-2.0.3.gem
Source128:      https://rubygems.org/downloads/cocoon-1.2.11.gem
Source129:      https://rubygems.org/downloads/codecov-0.1.10.gem
Source130:      https://rubygems.org/downloads/codemirror-rails-5.16.0.gem
Source131:      https://rubygems.org/downloads/coderay-1.1.2.gem
Source132:      https://rubygems.org/downloads/coffee-rails-4.2.2.gem
Source133:      https://rubygems.org/downloads/coffee-script-2.4.1.gem
Source134:      https://rubygems.org/downloads/coffee-script-source-1.12.2.gem
Source135:      https://rubygems.org/downloads/colorize-0.8.1.gem
Source136:      https://rubygems.org/downloads/concurrent-ruby-1.0.5.gem
Source137:      https://rubygems.org/downloads/concurrent-ruby-ext-1.0.5.gem
Source138:      https://rubygems.org/downloads/crack-0.4.3.gem
Source139:      https://rubygems.org/downloads/crass-1.0.3.gem
Source140:      https://rubygems.org/downloads/cssmin-1.0.3.gem
Source141:      https://rubygems.org/downloads/daemons-1.2.6.gem
Source142:      https://rubygems.org/downloads/dalli-2.7.6.gem
Source143:      https://rubygems.org/downloads/data_migrate-3.4.0.gem
Source144:      https://rubygems.org/downloads/database_cleaner-1.6.2.gem
Source145:      https://rubygems.org/downloads/delayed_job-4.1.4.gem
Source146:      https://rubygems.org/downloads/delayed_job_active_record-4.1.2.gem
Source147:      https://rubygems.org/downloads/diff-lcs-1.3.gem
Source148:      https://rubygems.org/downloads/docile-1.1.5.gem
Source149:      https://rubygems.org/downloads/equatable-0.5.0.gem
Source150:      https://rubygems.org/downloads/erubi-1.7.0.gem
Source151:      https://rubygems.org/downloads/escape_utils-1.2.1.gem
Source152:      https://rubygems.org/downloads/execjs-2.7.0.gem
Source153:      https://rubygems.org/downloads/factory_bot-4.8.2.gem
Source154:      https://rubygems.org/downloads/factory_bot_rails-4.8.2.gem
Source155:      https://rubygems.org/downloads/faker-1.8.7.gem
Source156:      https://rubygems.org/downloads/feature-1.4.0.gem
Source157:      https://rubygems.org/downloads/ffi-1.9.21.gem
Source159:      https://rubygems.org/downloads/flot-rails-0.0.7.gem
Source160:      https://rubygems.org/downloads/font-awesome-rails-4.7.0.2.gem
Source161:      https://rubygems.org/downloads/git-cop-2.1.0.gem
Source162:      https://rubygems.org/downloads/globalid-0.4.1.gem
Source163:      https://rubygems.org/downloads/gssapi-1.2.0.gem
Source164:      https://rubygems.org/downloads/haml-5.0.4.gem
Source165:      https://rubygems.org/downloads/haml_lint-0.27.0.gem
Source166:      https://rubygems.org/downloads/hashdiff-0.3.7.gem
Source167:      https://rubygems.org/downloads/i18n-0.9.5.gem
Source168:      https://rubygems.org/downloads/innertube-1.1.0.gem
Source169:      https://rubygems.org/downloads/joiner-0.3.4.gem
Source170:      https://rubygems.org/downloads/jquery-datatables-rails-3.4.0.gem
Source171:      https://rubygems.org/downloads/jquery-rails-4.3.1.gem
Source172:      https://rubygems.org/downloads/jquery-ui-rails-4.2.1.gem
Source173:      https://rubygems.org/downloads/json-2.1.0.gem
Source174:      https://rubygems.org/downloads/kaminari-1.1.1.gem
Source175:      https://rubygems.org/downloads/kaminari-actionview-1.1.1.gem
Source176:      https://rubygems.org/downloads/kaminari-activerecord-1.1.1.gem
Source177:      https://rubygems.org/downloads/kaminari-core-1.1.1.gem
Source178:      https://rubygems.org/downloads/kgio-2.11.0.gem
Source179:      https://rubygems.org/downloads/launchy-2.4.3.gem
Source180:      https://rubygems.org/downloads/loofah-2.2.0.gem
Source181:      https://rubygems.org/downloads/mail-2.7.0.gem
Source182:      https://rubygems.org/downloads/metaclass-0.0.4.gem
Source183:      https://rubygems.org/downloads/method_source-0.9.0.gem
Source184:      https://rubygems.org/downloads/middleware-0.1.0.gem
Source185:      https://rubygems.org/downloads/mini_mime-1.0.0.gem
Source186:      https://rubygems.org/downloads/mini_portile2-2.3.0.gem
Source187:      https://rubygems.org/downloads/minitest-5.11.3.gem
Source188:      https://rubygems.org/downloads/minitest-fail-fast-0.1.0.gem
Source189:      https://rubygems.org/downloads/minitest-reporters-1.1.19.gem
Source190:      https://rubygems.org/downloads/mocha-1.3.0.gem
Source191:      https://rubygems.org/downloads/momentjs-rails-2.17.1.gem
Source192:      https://rubygems.org/downloads/mousetrap-rails-1.4.6.gem
Source193:      https://rubygems.org/downloads/mysql2-0.4.10.gem
Source194:      https://rubygems.org/downloads/nio4r-2.2.0.gem
Source195:      https://rubygems.org/downloads/nokogiri-1.8.2.gem
Source196:      https://rubygems.org/downloads/nokogumbo-1.5.0.gem
Source197:      https://rubygems.org/downloads/nyan-cat-formatter-0.12.0.gem
Source198:      https://rubygems.org/downloads/parallel-1.12.0.gem
Source199:      https://rubygems.org/downloads/parser-2.5.0.2.gem
Source200:      https://rubygems.org/downloads/pastel-0.7.2.gem
Source201:      https://rubygems.org/downloads/path_expander-1.0.2.gem
Source202:      https://rubygems.org/downloads/peek-1.0.1.gem
Source203:      https://rubygems.org/downloads/peek-dalli-1.2.0.gem
Source204:      https://rubygems.org/downloads/peek-mysql2-1.2.0.gem
Source205:      https://rubygems.org/downloads/pkg-config-1.2.3.gem
Source206:      https://rubygems.org/downloads/poltergeist-1.17.0.gem
Source207:      https://rubygems.org/downloads/power_assert-1.1.1.gem
Source208:      https://rubygems.org/downloads/powerpack-0.1.1.gem
Source209:      https://rubygems.org/downloads/pry-0.11.3.gem
Source210:      https://rubygems.org/downloads/public_suffix-3.0.2.gem
Source211:      https://rubygems.org/downloads/pundit-1.1.0.gem
Source212:      https://rubygems.org/downloads/rack-2.0.4.gem
Source213:      https://rubygems.org/downloads/rack-test-0.8.2.gem
Source214:      https://rubygems.org/downloads/rails-5.1.5.gem
Source215:      https://rubygems.org/downloads/rails-controller-testing-1.0.2.gem
Source216:      https://rubygems.org/downloads/rails-dom-testing-2.0.3.gem
Source217:      https://rubygems.org/downloads/rails-html-sanitizer-1.0.3.gem
Source218:      https://rubygems.org/downloads/rails_tokeninput-1.7.0.gem
Source219:      https://rubygems.org/downloads/railties-5.1.5.gem
Source220:      https://rubygems.org/downloads/rainbow-2.2.2.gem
Source221:      https://rubygems.org/downloads/raindrops-0.18.0.gem
Source222:      https://rubygems.org/downloads/rake-12.3.0.gem
Source223:      https://rubygems.org/downloads/rantly-1.1.0.gem
Source224:      https://rubygems.org/downloads/rb-fsevent-0.10.2.gem
Source225:      https://rubygems.org/downloads/rb-inotify-0.9.10.gem
Source226:      https://rubygems.org/downloads/rdoc-6.0.1.gem
Source227:      https://rubygems.org/downloads/redcarpet-3.4.0.gem
Source228:      https://rubygems.org/downloads/refinements-5.0.2.gem
Source229:      https://rubygems.org/downloads/responders-2.4.0.gem
Source230:      https://rubygems.org/downloads/riddle-2.2.0.gem
Source231:      https://rubygems.org/downloads/rspec-3.5.0.gem
Source232:      https://rubygems.org/downloads/rspec-core-3.5.4.gem
Source233:      https://rubygems.org/downloads/rspec-expectations-3.5.0.gem
Source234:      https://rubygems.org/downloads/rspec-mocks-3.5.0.gem
Source235:      https://rubygems.org/downloads/rspec-rails-3.5.2.gem
Source236:      https://rubygems.org/downloads/rspec-support-3.5.0.gem
Source237:      https://rubygems.org/downloads/rubocop-0.51.0.gem
Source238:      https://rubygems.org/downloads/rubocop-rspec-1.20.1.gem
Source239:      https://rubygems.org/downloads/ruby-ldap-0.9.19.gem
Source240:      https://rubygems.org/downloads/ruby-progressbar-1.9.0.gem
Source241:      https://rubygems.org/downloads/ruby_parser-3.11.0.gem
Source242:      https://rubygems.org/downloads/runcom-2.0.1.gem
Source243:      https://rubygems.org/downloads/safe_yaml-1.0.4.gem
Source244:      https://rubygems.org/downloads/sanitize-4.6.0.gem
Source245:      https://rubygems.org/downloads/sass-3.5.3.gem
Source246:      https://rubygems.org/downloads/sass-listen-4.0.0.gem
Source247:      https://rubygems.org/downloads/sass-rails-5.0.7.gem
Source248:      https://rubygems.org/downloads/sexp_processor-4.10.1.gem
Source249:      https://rubygems.org/downloads/shoulda-matchers-3.1.2.gem
Source250:      https://rubygems.org/downloads/simplecov-0.14.1.gem
Source251:      https://rubygems.org/downloads/simplecov-html-0.10.1.gem
Source252:      https://rubygems.org/downloads/single_test-0.6.0.gem
Source253:      https://rubygems.org/downloads/sprite-factory-1.7.1.gem
Source254:      https://rubygems.org/downloads/sprockets-3.7.1.gem
Source255:      https://rubygems.org/downloads/sprockets-rails-3.2.1.gem
Source256:      https://rubygems.org/downloads/sysexits-1.2.0.gem
Source257:      https://rubygems.org/downloads/temple-0.8.0.gem
Source258:      https://rubygems.org/downloads/test-unit-3.2.7.gem
Source259:      https://rubygems.org/downloads/thinking-sphinx-3.4.2.gem
Source260:      https://rubygems.org/downloads/thor-0.20.0.gem
Source261:      https://rubygems.org/downloads/thread_safe-0.3.6.gem
Source262:      https://rubygems.org/downloads/tilt-2.0.8.gem
Source263:      https://rubygems.org/downloads/timecop-0.9.1.gem
Source264:      https://rubygems.org/downloads/tty-color-0.4.2.gem
Source265:      https://rubygems.org/downloads/tzinfo-1.2.5.gem
Source266:      https://rubygems.org/downloads/uglifier-4.1.6.gem
Source267:      https://rubygems.org/downloads/unicode-display_width-1.3.0.gem
Source268:      https://rubygems.org/downloads/unicorn-5.3.0.gem
Source269:      https://rubygems.org/downloads/unicorn-rails-2.2.1.gem
Source270:      https://rubygems.org/downloads/uniform_notifier-1.11.0.gem
Source271:      https://rubygems.org/downloads/url-0.3.2.gem
Source272:      https://rubygems.org/downloads/vcr-4.0.0.gem
Source273:      https://rubygems.org/downloads/voight_kampff-1.1.2.gem
Source274:      https://rubygems.org/downloads/webmock-3.3.0.gem
Source275:      https://rubygems.org/downloads/websocket-driver-0.6.5.gem
Source276:      https://rubygems.org/downloads/websocket-extensions-0.1.3.gem
Source277:      https://rubygems.org/downloads/xmlhash-1.3.7.gem
Source278:      https://rubygems.org/downloads/xmlrpc-0.3.0.gem
Source279:      https://rubygems.org/downloads/xpath-3.0.0.gem
Source280:      https://rubygems.org/downloads/yajl-ruby-1.3.1.gem
### GEMS END
# for rebuild_time
Requires:       perl(GD)

Requires:       ghostscript-fonts-std

%description -n obs-api
This is the API server instance, and the web client for the
OBS.

%package -n obs-utils
Summary:        The Open Build Service -- utilities
%if 0%{?suse_version} < 1210 && 0%{?suse_version:1}
Group:          Productivity/Networking/Web/Utilities
%endif
Requires:       build
Requires:       osc

%description -n obs-utils
obs_project_update is a tool to copy a packages of a project from one obs to another

%package -n obs-tests-appliance

Summary:  The Open Build Service -- Test cases for installed appliances

Requires: obs-server = %{version}
Requires: obs-api = %{version}

%if 0%{?suse_version} < 1210 && 0%{?suse_version:1}
Group:          Productivity/Networking/Web/Utilities
%endif

%description -n obs-tests-appliance
This package contains test cases for testing a installed appliances.
 Test cases can be for example:
 * checks for setup-appliance.sh
 * checks if database setup worked correctly
 * checks if required service came up properly

%package -n obs-cloud-uploader
Summary:       The Open Build Service -- Image Cloud Uploader
Requires:      obs-server
Requires:      aws-cli
Requires:      azure-cli
%if 0%{?suse_version} > 1315
Requires:      python3-ec2uploadimg
%else
Requires:      python-ec2uploadimg
%endif
Group:         Productivity/Networking/Web/Utilities

%description -n obs-cloud-uploader
This package contains all the necessary tools for upload images to the cloud.

#--------------------------------------------------------------------------------
%prep
# Ensure there are ruby, gem and irb commands without ruby suffix
mkdir ~/bin
for i in ruby gem irb; do ln -s /usr/bin/$i.ruby2.5 ~/bin/$i; done

%setup -q -n open-build-service-%version

# We don't need our docker files in our packages
rm -r src/{api,backend}/docker-files
rm src/api/Dockerfile.frontend-base

# drop build script, we require the installed one from own package
rm -rf src/backend/build

find -name .keep -o -name .gitignore | xargs rm -rf
# copy gem files into cache
mkdir -p src/api/vendor/cache
cp %{_sourcedir}/*.gem src/api/vendor/cache

%build
export PATH=~/bin:$PATH
export GEM_HOME=~/.gems
pushd src/api/
bundle config build.nokogiri --use-system-libraries
bundle --local --path %{buildroot}/%_libdir/obs-api/
popd

export DESTDIR=$RPM_BUILD_ROOT
# we need it for the test suite or it may silently succeed
test -x /usr/bin/Xvfb

#
# generate apidocs
#
make

%install
export DESTDIR=$RPM_BUILD_ROOT

%if 0%{?suse_version} < 1300
  perl -p -i -e 's/^APACHE_VHOST_CONF=.*/APACHE_VHOST_CONF=obs-apache2.conf/' Makefile.include
%endif

%if 0%{?fedora} || 0%{?rhel}
  # Fedora use different user:group for apache
  perl -p -i -e 's/^APACHE_USER=.*/APACHE_USER=apache/' Makefile.include
  perl -p -i -e 's/^APACHE_GROUP=.*/APACHE_GROUP=apache/' Makefile.include
%endif

# run gem clean up script
/usr/lib/rpm/gem_build_cleanup.sh %{buildroot}/%_libdir/obs-api/ruby/*/
# remove cached gems
rm -rf src/api/vendor/cache/*
# the examples folder contains a broken symlink which causes fdupes to fail
rm -rf %{buildroot}/%_libdir/obs-api/ruby/*/gems/database_cleaner-*/examples
# remove ffi backup file
rm -rf %{buildroot}/%_libdir/obs-api/ruby/*/gems/ffi-*/ext/ffi_c/libffi/fficonfig.h.in~
# fix broken symlink
pushd %{buildroot}/%_libdir/obs-api/ruby/*/gems/ffi-*/ext/ffi_c/libffi-*linux-gnu/include
ln -sf ../../libffi/src/x86/ffitarget.h ffitarget.h
popd
# Patch from unicorn gem
sed -i 's/\/this\/will\/be\/overwritten\/or\/wrapped\/anyways\/do\/not\/worry\/ruby/\/usr\/bin\/ruby/' %{buildroot}/%_libdir/obs-api/ruby/*/gems/unicorn*/bin/unicorn
sed -i 's/\/this\/will\/be\/overwritten\/or\/wrapped\/anyways\/do\/not\/worry\/ruby/\/usr\/bin\/ruby/' %{buildroot}/%_libdir/obs-api/ruby/*/gems/unicorn*/bin/unicorn_rails
# Patch from diff-lcs gem
sed -i 's/#!ruby -w/#!\/usr\/bin\/ruby -w/' %{buildroot}/%_libdir/obs-api/ruby/*/gems/diff-lcs*/bin/htmldiff
sed -i 's/#!ruby -w/#!\/usr\/bin\/ruby -w/' %{buildroot}/%_libdir/obs-api/ruby/*/gems/diff-lcs*/bin/ldiff

export OBS_VERSION="%{version}"
DESTDIR=%{buildroot} make install FILLUPDIR=%{_fillupdir}
if [ -f %{_sourcedir}/open-build-service.obsinfo ]; then
    sed -n -e 's/commit: \(.\+\)/\1/p' %{_sourcedir}/open-build-service.obsinfo > %{buildroot}/srv/www/obs/api/last_deploy
else
    echo "" > %{buildroot}/srv/www/obs/api/last_deploy
fi
#
# turn duplicates into hard links
#
# There's dupes between webui and api:
%if 0%{?suse_version} >= 1030
%fdupes $RPM_BUILD_ROOT/srv/www/obs
%endif

# fix build for SLE 11
%if 0%{?suse_version} < 1315
touch %{buildroot}/%{secret_key_file}
chmod 0640 %{buildroot}/%{secret_key_file}
%endif

# drop testcases for now
rm -rf %{buildroot}/srv/www/obs/api/spec

# fail when Makefiles created a directory
if ! test -L %{buildroot}/usr/lib/obs/server/build; then
  echo "/usr/lib/obs/server/build is not a symlink!"
  exit 1
fi

install -m 755 $RPM_BUILD_DIR/open-build-service-%version/dist/clouduploader.rb $RPM_BUILD_ROOT/%{_bindir}/clouduploader
mkdir -p $RPM_BUILD_ROOT/etc/obs/cloudupload
install -m 644 $RPM_BUILD_DIR/open-build-service-%version/dist/ec2utils.conf.example $RPM_BUILD_ROOT/etc/obs/cloudupload/.ec2utils.conf
mkdir -p $RPM_BUILD_ROOT/etc/obs/cloudupload/.aws
install -m 644 $RPM_BUILD_DIR/open-build-service-%version/dist/aws_credentials.example $RPM_BUILD_ROOT/etc/obs/cloudupload/.aws/credentials

%check
%if 0%{?disable_obs_test_suite}
echo "WARNING:"
echo "WARNING: OBS test suite got skipped!"
echo "WARNING:"
exit 0
%endif

export DESTDIR=$RPM_BUILD_ROOT
# check installed backend
pushd $RPM_BUILD_ROOT/usr/lib/obs/server/
rm -rf build
ln -sf /usr/lib/build build # just for %%check, it is a %%ghost
popd

# run in build environment
pushd src/backend/
rm -rf build
ln -sf /usr/lib/build build
popd

####
# start backend testing
pushd $RPM_BUILD_ROOT/usr/lib/obs/server/
%if 0%{?disable_obs_backend_test_suite:1} < 1
# TODO: move syntax check to backend test suite
for i in bs_*; do
  perl -wc "$i"
done
bash $RPM_BUILD_DIR/open-build-service-%version/src/backend/testdata/test_dispatcher || exit 1
popd

make -C src/backend test
%endif

####
# start api testing
#
%if 0%{?disable_obs_frontend_test_suite:1} < 1
# UI tests are not needed for non x86 architectures
%ifnarch %ix86 x86_64
rm -r src/api/spec/features/
%endif  
make -C src/api test
%endif

####
# distribution tests
%if 0%{?disable_obs_dist_test_suite:1} < 1
make -C dist test
%endif

%pre
getent passwd obsservicerun >/dev/null || \
    /usr/sbin/useradd -r -g obsrun -d /usr/lib/obs -s %{sbin}/nologin \
    -c "User for the build service source service" obsservicerun

%service_add_pre obsdeltastore.service

exit 0

# create user and group in advance of obs-server
%pre -n obs-common
getent group obsrun >/dev/null || /usr/sbin/groupadd -r obsrun
getent passwd obsrun >/dev/null || \
    /usr/sbin/useradd -r -g obsrun -d /usr/lib/obs -s %{sbin}/nologin \
    -c "User for build service backend" obsrun
exit 0

%preun
%stop_on_removal obssrcserver obsrepserver obsdispatcher obsscheduler obspublisher obswarden obssigner obsdodup obsservicedispatch obsservice

%service_del_preun obsdeltastore.service

%preun -n obs-worker
%stop_on_removal obsworker

%preun -n obs-cloud-uploader
%stop_on_removal obsclouduploadworker obsclouduploadserver

%post
%if 0%{?suse_version} >= 1315
%reload_on_update obssrcserver obsrepserver obsdispatcher obspublisher obswarden obssigner obsdodup obsservicedispatch obsservice
%else
%restart_on_update obssrcserver obsrepserver obsdispatcher obspublisher obswarden obssigner obsdodup obsservicedispatch obsservice
%endif
# systemd kills the init script executing the reload first on reload....
%restart_on_update obsscheduler
%service_add_post obsdeltastore.service

%post -n obs-cloud-uploader
%if 0%{?suse_version} >= 1315
%reload_on_update obsservice obsclouduploadworker obsclouduploadserver
%else
%restart_on_update obsservice obsclouduploadworker obsclouduploadserver
%endif

%posttrans
[ -d /srv/obs ] || install -d -o obsrun -g obsrun /srv/obs
# this changes from directory to symlink. rpm can not handle this itself.
if [ -e /usr/lib/obs/server/build -a ! -L /usr/lib/obs/server/build ]; then
  rm -rf /usr/lib/obs/server/build
fi
if [ ! -e /usr/lib/obs/server/build ]; then
  ln -sf ../../build /usr/lib/obs/server/build
fi

%postun
%insserv_cleanup
%service_del_postun obsdeltastore.service
# cleanup empty directory just in case
rmdir /srv/obs 2> /dev/null || :

%verifyscript -n obs-server
%verify_permissions

%post -n obs-worker
# NOT used on purpose: restart_on_update obsworker
# This can cause problems when building chroot
# and bs_worker is anyway updating itself at runtime based on server code

%pre -n obs-api
getent passwd obsapidelayed >/dev/null || \
  /usr/sbin/useradd -r -s /bin/bash -c "User for build service api delayed jobs" -d /srv/www/obs/api -g www obsapidelayed

%post -n obs-common
%{fillup_and_insserv -n obs-server}

%post -n obs-api
if [ -e /srv/www/obs/frontend/config/database.yml ] && [ ! -e /srv/www/obs/api/config/database.yml ]; then
  cp /srv/www/obs/frontend/config/database.yml /srv/www/obs/api/config/database.yml
fi
for i in production.rb ; do
  if [ -e /srv/www/obs/frontend/config/environments/$i ] && [ ! -e /srv/www/obs/api/config/environments/$i ]; then
    cp /srv/www/obs/frontend/config/environments/$i /srv/www/obs/api/config/environments/$i
  fi
done

if [ ! -e %{secret_key_file} ]; then
  pushd .
  cd /srv/www/obs/api/config
  ( umask 0077; RAILS_ENV=production bundle.ruby2.5 exec rails.ruby2.5 secret > %{secret_key_file} ) || exit 1
  popd
fi
chmod 0640 %{secret_key_file}
chown root.www %{secret_key_file}

# update config
sed -i -e 's,[ ]*adapter: mysql$,  adapter: mysql2,' /srv/www/obs/api/config/database.yml
touch /srv/www/obs/api/log/production.log
chown %{apache_user}:%{apache_group} /srv/www/obs/api/log/production.log

%restart_on_update memcached

%postun -n obs-api
%insserv_cleanup
%restart_on_update obsapisetup
%restart_on_update apache2
%restart_on_update obsapidelayed

%files
%defattr(-,root,root)
%doc dist/{README.UPDATERS,README.SETUP} docs/openSUSE.org.xml ReleaseNotes-* README.md COPYING AUTHORS
%dir /etc/slp.reg.d
%dir /usr/lib/obs
%dir /usr/lib/obs/server
%config(noreplace) /etc/logrotate.d/obs-server
/etc/init.d/obsdispatcher
/etc/init.d/obspublisher
/etc/init.d/obsrepserver
/etc/init.d/obsscheduler
/etc/init.d/obssrcserver
/etc/init.d/obswarden
/etc/init.d/obsdodup
%{_unitdir}/obsdeltastore.service
/etc/init.d/obsservicedispatch
/etc/init.d/obssigner
/usr/sbin/obs_admin
/usr/sbin/obs_serverstatus
/usr/sbin/rcobsdispatcher
/usr/sbin/rcobspublisher
/usr/sbin/rcobsrepserver
/usr/sbin/rcobsscheduler
/usr/sbin/rcobssrcserver
/usr/sbin/rcobswarden
/usr/sbin/rcobsdodup
/usr/sbin/rcobsdeltastore
/usr/sbin/rcobsservicedispatch
/usr/sbin/rcobssigner
/usr/lib/obs/server/plugins
/usr/lib/obs/server/BSDispatcher
/usr/lib/obs/server/BSRepServer
/usr/lib/obs/server/BSSched
/usr/lib/obs/server/BSSrcServer
/usr/lib/obs/server/XML
/usr/lib/obs/server/*.pm
/usr/lib/obs/server/BSConfig.pm.template
/usr/lib/obs/server/DESIGN
/usr/lib/obs/server/License
/usr/lib/obs/server/README
/usr/lib/obs/server/bs_admin
/usr/lib/obs/server/bs_cleanup
/usr/lib/obs/server/bs_archivereq
/usr/lib/obs/server/bs_check_consistency
/usr/lib/obs/server/bs_deltastore
/usr/lib/obs/server/bs_servicedispatch
/usr/lib/obs/server/bs_dodup
/usr/lib/obs/server/bs_getbinariesproxy
/usr/lib/obs/server/bs_mergechanges
/usr/lib/obs/server/bs_mkarchrepo
/usr/lib/obs/server/bs_notar
/usr/lib/obs/server/bs_regpush
/usr/lib/obs/server/bs_dispatch
/usr/lib/obs/server/bs_publish
/usr/lib/obs/server/bs_repserver
/usr/lib/obs/server/bs_sched
/usr/lib/obs/server/bs_serverstatus
/usr/lib/obs/server/bs_srcserver
/usr/lib/obs/server/bs_worker
/usr/lib/obs/server/bs_signer
/usr/lib/obs/server/bs_warden
/usr/lib/obs/server/worker
/usr/lib/obs/server/worker-deltagen.spec
%config(noreplace) /usr/lib/obs/server/BSConfig.pm
%config(noreplace) /etc/slp.reg.d/*
# created via %%post, since rpm fails otherwise while switching from
# directory to symlink
%ghost /usr/lib/obs/server/build

# formerly obs-source_service
/etc/init.d/obsservice
%config(noreplace) /etc/logrotate.d/obs-source_service
%config(noreplace) /etc/cron.d/cleanup_scm_cache
/usr/sbin/rcobsservice
/usr/lib/obs/server/bs_service
/usr/lib/obs/server/call-service-in-docker.sh
/usr/lib/obs/server/cleanup_scm_cache

# formerly obs-productconverter
/usr/bin/obs_productconvert
/usr/lib/obs/server/bs_productconvert

# add obsservicerun user into docker group if docker
# gets installed
%triggerin -n obs-server -- docker
usermod -a -G docker obsservicerun

%files -n obs-worker
%defattr(-,root,root)
/etc/init.d/obsworker
/usr/sbin/rcobsworker

%files -n obs-api
%defattr(-,root,root)
%doc dist/{README.UPDATERS,README.SETUP} docs/openSUSE.org.xml ReleaseNotes-* README.md COPYING AUTHORS
/srv/www/obs/overview

/srv/www/obs/api/config/thinking_sphinx.yml.example
%config(noreplace) /etc/cron.d/obs_api_delayed_jobs_monitor
%config(noreplace) /srv/www/obs/api/config/thinking_sphinx.yml
%attr(-,%{apache_user},%{apache_group}) %config(noreplace) /srv/www/obs/api/config/production.sphinx.conf

%dir /srv/www/obs
%dir /srv/www/obs/api
%dir /srv/www/obs/api/config
%config(noreplace) /srv/www/obs/api/config/cable.yml
%config(noreplace) /srv/www/obs/api/config/feature.yml
%config(noreplace) /srv/www/obs/api/config/puma.rb
%config(noreplace) /srv/www/obs/api/config/secrets.yml
%config(noreplace) /srv/www/obs/api/config/spring.rb
%config(noreplace) /srv/www/obs/api/config/crawler-user-agents.json
/srv/www/obs/api/config/initializers
%dir /srv/www/obs/api/config/environments
%dir /srv/www/obs/api/files
%dir /srv/www/obs/api/db
/srv/www/obs/api/db/checker.rb
/srv/www/obs/api/Gemfile
/srv/www/obs/api/last_deploy
/srv/www/obs/api/Gemfile.lock
/srv/www/obs/api/config.ru
/srv/www/obs/api/config/application.rb
/srv/www/obs/api/config/clock.rb
%config(noreplace) /etc/logrotate.d/obs-api
/etc/init.d/obsapidelayed
/etc/init.d/obsapisetup
/usr/sbin/rcobsapisetup
/usr/sbin/rcobsapidelayed
/srv/www/obs/api/app
%attr(-,%{apache_user},%{apache_group})  /srv/www/obs/api/db/structure.sql
%attr(-,%{apache_user},%{apache_group})  /srv/www/obs/api/db/data_schema.rb
/srv/www/obs/api/db/attribute_descriptions.rb
/srv/www/obs/api/db/data
/srv/www/obs/api/db/migrate
/srv/www/obs/api/db/seeds.rb
/srv/www/obs/api/files/wizardtemplate.spec
/srv/www/obs/api/lib
/srv/www/obs/api/public
/srv/www/obs/api/Rakefile
/srv/www/obs/api/script
/srv/www/obs/api/bin
/srv/www/obs/api/test
/srv/www/obs/docs


/srv/www/obs/api/config/locales
/srv/www/obs/api/vendor
/srv/www/obs/api/vendor/diststats

#
# some files below config actually are _not_ config files
# so here we go, file by file
#

/srv/www/obs/api/config/boot.rb
/srv/www/obs/api/config/routes.rb
/srv/www/obs/api/config/environments/development.rb
/srv/www/obs/api/config/unicorn
%attr(0640,root,%apache_group) %config(noreplace) %verify(md5) /srv/www/obs/api/config/database.yml
%attr(0640,root,%apache_group) /srv/www/obs/api/config/database.yml.example
%attr(0644,root,root) %config(noreplace) %verify(md5) /srv/www/obs/api/config/options.yml
%attr(0644,root,root) /srv/www/obs/api/config/options.yml.example
%dir %attr(0755,%apache_user,%apache_group) /srv/www/obs/api/db/sphinx
%dir %attr(0755,%apache_user,%apache_group) /srv/www/obs/api/db/sphinx/production
/srv/www/obs/api/.bundle

%config /srv/www/obs/api/config/environment.rb
%config /srv/www/obs/api/config/environments/production.rb
%config /srv/www/obs/api/config/environments/test.rb
%config /srv/www/obs/api/config/environments/stage.rb

%dir %attr(-,%{apache_user},%{apache_group}) /srv/www/obs/api/log
%attr(-,%{apache_user},%{apache_group}) /srv/www/obs/api/tmp

# these dirs primarily belong to apache2:
%dir /etc/apache2
%dir /etc/apache2/vhosts.d
%config(noreplace) /etc/apache2/vhosts.d/obs.conf

%defattr(0644,wwwrun,www)
%ghost /srv/www/obs/api/log/access.log
%ghost /srv/www/obs/api/log/backend_access.log
%ghost /srv/www/obs/api/log/delayed_job.log
%ghost /srv/www/obs/api/log/error.log
%ghost /srv/www/obs/api/log/lastevents.access.log
%ghost /srv/www/obs/api/log/production.log
%ghost %attr(0640,root,www) %secret_key_file

%files -n obs-common
%defattr(-,root,root)
%{_fillupdir}/sysconfig.obs-server
/usr/lib/obs/server/setup-appliance.sh
/etc/init.d/obsstoragesetup
/usr/sbin/rcobsstoragesetup


%files -n obs-utils
%defattr(-,root,root)
/usr/sbin/obs_project_update

%files -n obs-tests-appliance
%defattr(-,root,root)
%dir /usr/lib/obs/tests/
%dir /usr/lib/obs/tests/appliance
/usr/lib/obs/tests/appliance/*

%files -n obs-cloud-uploader
%defattr(-,root,root)
/etc/init.d/obsclouduploadworker
/etc/init.d/obsclouduploadserver
/usr/sbin/rcobsclouduploadworker
/usr/sbin/rcobsclouduploadserver
/usr/lib/obs/server/bs_clouduploadserver
/usr/lib/obs/server/bs_clouduploadworker
%{_bindir}/clouduploader
%dir /etc/obs
%dir /etc/obs/cloudupload
%dir /etc/obs/cloudupload/.aws
%config(noreplace) /etc/obs/cloudupload/.aws/credentials
%config /etc/obs/cloudupload/.ec2utils.conf

%package -n obs-container-registry
Summary:        The Open Build Service -- container registry
%if 0%{?suse_version} < 1210 && 0%{?suse_version:1}
Group:          Productivity/Networking/Web/Utilities
%endif
Requires:       docker-distribution-registry

%description -n obs-container-registry
The OBS Container Registry, based on the docker registry, which allows

* anonymous pulls from anywhere
* anonymous pushes from localhost.

This is done by proxying access to the registry through
apache and restricting any other http method than GET and HEAD
to localhost.


%files -n obs-container-registry
%defattr(-,root,root)
%dir /srv/www/obs/container-registry
%dir /srv/www/obs/container-registry/log
%dir /srv/www/obs/container-registry/htdocs
%config /etc/apache2/vhosts.d/obs-container-registry.conf

%changelog
