module Webui::Projects::StatusHelper
  def parse_status(package)
    outs = []
    icon = "ok"
    sortkey = nil

    if package['requests_from'].empty?
      package['problems'].sort.each do |c|
        if c == 'different_changes'
          age = distance_of_time_in_words_to_now(package['develmtime'].to_i)
          outs << link_to("Different changes in devel project (since #{age})",
                          package_rdiff_path(project: package['develproject'], package: package['develpackage'], oproject: @project.name, opackage: package['name']))
          sortkey = "5-changes-#{package['develmtime']}-#{package['name']}"
          icon = "changes"
        elsif c == 'different_sources'
          age = distance_of_time_in_words_to_now(package['develmtime'].to_i)
          outs << link_to("Different sources in devel project (since #{age})", package_rdiff_path(project: package['develproject'], package: package['develpackage'],
                                                                                                  oproject: @project.name, opackage: package['name']))
          sortkey = "6-changes-#{package['develmtime']}-" + package['name']
          icon = "changes"
        elsif c == 'diff_against_link'
          outs << link_to("Linked package is different", package_rdiff_path(oproject: package['lproject'], opackage: package['lpackage'],
                                                                            project: @project.name, package: package['name']))
          sortkey = "7-changes" + package['name']
          icon = "changes"
        elsif c =~ /^error-/
          outs << link_to(c[6..-1], package_show_path(project: package['develproject'], package: package['develpackage']))
          sortkey = "1-problem-" + package['name']
          icon = "error"
        elsif c == 'currently_declined'
          outs << link_to("Current sources were declined: request #{package['currently_declined']}",
                          request_show_path(number: package['currently_declined']))
          sortkey = "2-declines-" + package['name']
          icon = "error"
        else
          outs << link_to(c, package_show_path(project: package['develproject'], package: package['develpackage']))
          sortkey = "1-changes" + package['name']
          icon = "error"
        end
      end
    end
    package['requests_to'].each do |number|
      outs.unshift(("Request %s to %s" % [link_to(number, request_show_path(number: number)), h(package['develproject'])]).html_safe)
      icon = "changes"
      sortkey = "3-request%06d-%s" % [ 999999 - number, package['name']]
    end
    package['requests_from'].each do |number|
      outs.unshift(("Request %s to %s" % [link_to(number, request_show_path(number: number)), h(@project.name)]).html_safe)
      icon = "changes"
      sortkey = "2-drequest%06d-%s" % [ 999999 - number, package['name']]
    end
    # ignore the upstream version if there are already changes pending
    if package['upstream_version'] && sortkey.nil?
      if package['upstream_url']
        outs << "New upstream version " + link_to(package['upstream_version'], package['upstream_url']) + " available"
      else
        outs << "New upstream version #{package['upstream_version']} available"
      end
      sortkey = "8-outdated-" + package['name']
    end
    if package['firstfail']
      outs.unshift(link_to("Fails", package_live_build_log_path(arch: h(package['failedarch']), repository: h(package['failedrepo']),
                                                                project: h(@project.name), package: h(package['name']))).html_safe +
      " since #{distance_of_time_in_words_to_now(package['firstfail'].to_i)}")
      icon = "error"
      sortkey = '1-fails-%010d-%s' % [ Time.now.to_i - package['firstfail'], package['name'] ]
    elsif package['failedcomment'] && User.current.can_modify?(@project.api_obj)
      comments_to_clear << package['failedcomment']
    end
    unless sortkey
      sortkey = "9-ok-" + package['name']
    end

    { summary: outs, sortkey: sortkey, icon_type: icon }
  end
end
