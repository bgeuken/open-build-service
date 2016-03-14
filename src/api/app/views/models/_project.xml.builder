project_attributes = { name: my_model.name }
# Check if the project has a special type defined (like maintenance)
project_attributes[:kind] = my_model.kind unless my_model.is_standard?

xml.project(project_attributes) do
  xml.title(my_model.title)
  xml.description(my_model.description)

  my_model.linkedprojects.each do |l|
    if l.linked_db_project
      xml.link(project: l.linked_db_project.name)
    else
      xml.link(project: l.linked_remote_project_name)
    end
  end

  xml.remoteurl(my_model.remoteurl) unless my_model.remoteurl.blank?
  xml.remoteproject(my_model.remoteproject) unless my_model.remoteproject.blank?
  xml.devel(project: my_model.develproject.name) unless my_model.develproject.nil?

  my_model.render_relationships(xml)

  repos = my_model.repositories.not_remote.sort { |a, b| b.name <=> a.name }
  FlagHelper.flag_types.each do |flag_name|
    flaglist = my_model.type_flags(flag_name)
    xml.send(flag_name) do
      flaglist.each do |flag|
        flag.to_xml(xml)
      end
    end unless flaglist.empty?
  end

  repos.each do |repo|
    params = {}
    params[:name] = repo.name
    params[:rebuild] = repo.rebuild if repo.rebuild
    params[:block] = repo.block if repo.block
    params[:linkedbuild] = repo.linkedbuild if repo.linkedbuild
    xml.repository(params) do |xml_repository|
      repo.dod_sources.each do |dod_source|
        params = {arch: dod_source.arch, url: dod_source.url, repotype: dod_source.repotype}
        xml_repository.download(params) do |xml_download|
          xml_download.archfilter dod_source.archfilter if dod_source.archfilter
          unless dod_source.masterurl.blank?
            params = {url: dod_source.masterurl}
            params[:sslfingerprint] = dod_source.mastersslfingerprint
            xml_download.master(params)
          end
          xml_download.pubkey dod_source.pubkey if dod_source.pubkey
        end
      end
      repo.release_targets.each do |rt|
        params = {}
        params[:project] = rt.target_repository.project.name
        params[:repository] = rt.target_repository.name
        params[:trigger] = rt.trigger unless rt.trigger.blank?
        xml_repository.releasetarget(params)
      end
      if repo.hostsystem
        xml_repository.hostsystem(:project => repo.hostsystem.project.name, :repository => repo.hostsystem.name)
      end
      repo.path_elements.includes(:link).each do |pe|
        if pe.link.remote_project_name
          project_name = pe.link.project.name+":"+pe.link.remote_project_name
        else
          project_name = pe.link.project.name
        end
        xml_repository.path(:project => project_name, :repository => pe.link.name)
      end
      repo.repository_architectures.joins(:architecture).pluck("architectures.name").each do |arch|
        xml_repository.arch arch
      end
    end
  end

  unless MaintainedProject.where(maintenance_project_id: my_model.id).empty?
    xml.maintenance do |maintenance|
      MaintainedProject.where(maintenance_project_id: my_model.id).each do |mp|
        maintenance.maintains(:project => mp.project.name)
      end
    end
  end

end
