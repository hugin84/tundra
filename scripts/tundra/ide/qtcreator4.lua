module(..., package.seeall)

local native  = require "tundra.native"
local nodegen = require "tundra.nodegen"
local path    = require "tundra.path"
local util    = require "tundra.util"
local ide_com = require "tundra.ide.ide-common"

local LF = "\n"
if native.host_platform == "windows" then
  LF = "\r\n"
end

local qtcreator_generator = {}
qtcreator_generator.__index = qtcreator_generator

nodegen.set_ide_backend(function(...)
  local state = setmetatable({}, qtcreator_generator)
  state:generate_files(...)
end)

local project_types = ide_com.project_types


local function get_common_dir(sources)
  local dir_tokens = {}
  local min_dir_tokens = nil
  for _, path in ipairs(sources) do
    if not tundra.path.is_absolute(path) then
      local subdirs = {}
      for subdir in path:gmatch("([^/]+)/") do
        subdirs[#subdirs + 1] = subdir
      end

      if not min_dir_tokens then
        dir_tokens = subdirs
        min_dir_tokens = #subdirs
      else
        for i = 1, #dir_tokens do
          if dir_tokens[i] ~= subdirs[i] then
            min_dir_tokens = (i - 1)
            while #dir_tokens >= i do
              table.remove(dir_tokens)
            end
            break
          end
        end
      end
    end
  end

  if(min_dir_tokens) then
    while #dir_tokens > min_dir_tokens do
      table.remove(dir_tokens)
    end
  end

  local result = table.concat(dir_tokens, SEP)
  if #result > 0 then
    result = result .. SEP
  end
  return result
end


function string:split(sep)
  local sep, fields = sep or "/", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end


local function make_meta_project(base_dir, data, solution_folder)
  native.mkdir(base_dir .. solution_folder)
  data.IdeGenerationHints = { QtCreator = { SolutionFolder = solution_folder } }
  data.IsMeta             = true
  data.RelativeFilename   = data.Name .. ".pro"
  data.Filename           = base_dir .. solution_folder ..SEP .. data.RelativeFilename
  data.Type               = "meta"
  if not data.Sources then
    data.Sources          = {}
  end
  return data
end


local function write_editor_settings_plugin_settings(p)
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.EditorSettings</variable>", LF)
  p:write("  <valuemap type=\"QVariantMap\">", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.AutoIndent\">true</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.AutoSpacesForTabs\">false</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.CamelCaseNavigation\">true</value>", LF)
  p:write("   <valuemap type=\"QVariantMap\" key=\"EditorConfiguration.CodeStyle.0\">", LF)
  p:write("    <value type=\"QString\" key=\"language\">Cpp</value>", LF)
  p:write("    <valuemap type=\"QVariantMap\" key=\"value\">", LF)
  p:write("     <value type=\"QByteArray\" key=\"CurrentPreferences\">CppGlobal</value>", LF)
  p:write("    </valuemap>", LF)
  p:write("   </valuemap>", LF)
  p:write("   <valuemap type=\"QVariantMap\" key=\"EditorConfiguration.CodeStyle.1\">", LF)
  p:write("    <value type=\"QString\" key=\"language\">QmlJS</value>", LF)
  p:write("    <valuemap type=\"QVariantMap\" key=\"value\">", LF)
  p:write("     <value type=\"QByteArray\" key=\"CurrentPreferences\">QmlJSGlobal</value>", LF)
  p:write("    </valuemap>", LF)
  p:write("   </valuemap>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.CodeStyle.Count\">2</value>", LF)
  p:write("   <value type=\"QByteArray\" key=\"EditorConfiguration.Codec\">UTF-8</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.ConstrainTooltips\">false</value>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.IndentSize\">4</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.KeyboardTooltips\">false</value>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.MarginColumn\">80</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.MouseHiding\">true</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.MouseNavigation\">true</value>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.PaddingMode\">1</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.ScrollWheelZooming\">true</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.ShowMargin\">false</value>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.SmartBackspaceBehavior\">0</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.SmartSelectionChanging\">true</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.SpacesForTabs\">true</value>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.TabKeyBehavior\">0</value>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.TabSize\">4</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.UseGlobal\">true</value>", LF)
  p:write("   <value type=\"int\" key=\"EditorConfiguration.Utf8BomBehavior\">1</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.addFinalNewLine\">true</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.cleanIndentation\">true</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.cleanWhitespace\">true</value>", LF)
  p:write("   <value type=\"QString\" key=\"EditorConfiguration.ignoreFileTypes\">*.md, *.MD, Makefile</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.inEntireDocument\">false</value>", LF)
  p:write("   <value type=\"bool\" key=\"EditorConfiguration.skipTrailingWhitespace\">true</value>", LF)
  p:write("  </valuemap>", LF)
  p:write(" </data>", LF)
  -- empty plugin settings
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.PluginSettings</variable>", LF)
  p:write("  <valuemap type=\"QVariantMap\">", LF)
  p:write("  </valuemap>", LF)
  p:write(" </data>", LF)
end


local function make_project_data(units_raw, env, proj_extension, hints, ide_script)
  local cwd = native.getcwd()

  -- Filter out stuff we don't care about.
  local units = util.filter(units_raw, function (u)
    return u.Decl.Name and project_types[u.Keyword]
  end)

  local base_dir = (hints.QtCreatorSolutionDir and (hints.QtCreatorSolutionDir .. SEP)) or env:interpolate('$(OBJECTROOT)$(SEP)')
  native.mkdir(base_dir)

  local project_by_name = {}
  local all_sources  = {}
  local dag_node_lut = {} -- lookup table of all named, top-level DAG nodes 
  local name_to_dags = {} -- table mapping unit name to array of dag nodes (for configs)

  -- Map out all top-level DAG nodes
  for _, unit in ipairs(units) do
    local decl = unit.Decl

    local dag_nodes = assert(decl.__DagNodes, "no dag nodes for " .. decl.Name)
    for build_id, dag_node in pairs(dag_nodes) do
      dag_node_lut[dag_node] = unit
      local array = name_to_dags[decl.Name]
      if not array then
        array = {}
        name_to_dags[decl.Name] = array
      end
      array[#array + 1] = dag_node
    end
  end

  local function get_output_project(name)
    if not project_by_name[name] then
      local relative_fn = name .. proj_extension
      native.mkdir(base_dir .. name)
      project_by_name[name] = {
        Name             = name,
        Sources          = {},
        RelativeFilename = relative_fn,
        Filename         = base_dir .. name .. SEP .. relative_fn,
      }
    end
    return project_by_name[name]
  end

  -- Sort units based on dependency complexity. We want to visit the leaf nodes
  -- first so that any source file references are picked up as close to the
  -- bottom of the dependency chain as possible.
  local unit_weights = {}
  for _, unit in ipairs(units) do
    local decl = unit.Decl
    local stack = { }
    for _, dag in pairs(decl.__DagNodes) do
      stack[#stack + 1] = dag
    end
    local weight = 0
    while #stack > 0 do
      local node = table.remove(stack)
      if dag_node_lut[node] then
        weight = weight + 1
      end
      for _, dep in util.nil_ipairs(node.deps) do
        stack[#stack + 1] = dep
      end
    end
    unit_weights[unit] = weight
  end

  table.sort(units, function (a, b)
    return unit_weights[a] < unit_weights[b]
  end)

  -- Keep track of what source files have already been grabbed by other projects.
  local grabbed_sources = {}

  for _, unit in ipairs(units) do
    local decl = unit.Decl
    local name = decl.Name

    local source_lut = {}
    local generated_lut = {}
    for build_id, dag_node in pairs(decl.__DagNodes) do
      ide_com.get_sources(dag_node, source_lut, generated_lut, 0, dag_node_lut)
    end

    -- Explicitly add all header files too as they are not picked up from the DAG
    -- Also pick up headers from non-toplevel DAGs we're depending on
    ide_com.get_headers(unit, source_lut, dag_node_lut, name_to_dags)

    -- Figure out which project should get this data.
    local output_name = name
    local ide_hints = unit.Decl.IdeGenerationHints
    if ide_hints then
      if ide_hints.OutputProject then
        output_name = ide_hints.OutputProject
      end
    end

    local proj = get_output_project(output_name)

    if output_name == name then
      -- This unit is the real thing for this project, not something that's
      -- just being merged into it (like an ObjGroup). Set some more attributes.
      proj.IdeGenerationHints = ide_hints
      proj.DagNodes           = decl.__DagNodes
      proj.Unit               = unit
    end

    for src, _ in pairs(source_lut) do
      local norm_src = path.normalize(src)
      if not grabbed_sources[norm_src] then
        grabbed_sources[norm_src] = unit
        local is_generated = generated_lut[src]
        proj.Sources[#proj.Sources+1] = {
          Path      = norm_src,
          Generated = is_generated,
        }
      end
    end
  end

  -- Get all accessed Lua files
  local accessed_lua_files = util.table_keys(get_accessed_files())

  -- Filter out the ones that belong to this build (exclude ones coming from Tundra) 
  local function is_non_tundra_lua_file(p)
    return not path.is_absolute(p)
  end
  local function make_src_node(p)
    return { Path = path.normalize(p) }
  end
  local source_list = util.map(util.filter(accessed_lua_files, is_non_tundra_lua_file), make_src_node)

  local solution_hints = hints.QtCreatorSolution
  if not solution_hints then
    print("No IdeGenerationHints.QtCreatorSolution specified - using defaults")
    solution_hints = {
      ['tundra-generated.pro'] = {}
    }
  end

  local projects = util.table_values(project_by_name)
  local vanilla_projects = util.clone_array(projects)

  local solutions = {}

  -- Create meta project to regenerate solutions/projects. Added to every solution.
  local regen_meta_proj = make_meta_project(base_dir, {
    Name               = "00-Regenerate-Projects",
    FriendlyName       = "Regenerate Solution and Projects",
    BuildCommand       = ide_com.project_regen_commandline(ide_script),
  }, "build_system_meta_regen")

  projects[#projects + 1] = regen_meta_proj

  for name, data in pairs(solution_hints) do
    local sln_projects
    local ext_projects = {}
    if data.Projects then
      sln_projects = {}
      for _, pname in ipairs(data.Projects) do
        local pp = project_by_name[pname]
        if not pp then
          errorf("can't find project %s for inclusion in %s -- check your QtCreatorSolution data", pname, name)
        end
        sln_projects[#sln_projects + 1] = pp
      end
    else
      -- All the projects (that are not meta)
      sln_projects = util.clone_array(vanilla_projects)
    end

    for _, ext in util.nil_ipairs(data.ExternalProjects) do
      ext_projects[#ext_projects + 1] = ext
    end

    -- Create meta project to build solution
    local meta_proj = make_meta_project(base_dir, {
        Name               = "00-tundra-" .. path.drop_suffix(name),
      FriendlyName       = "Build This Solution",
      BuildByDefault     = true,
      Sources            = source_list,
      BuildProjects      = util.clone_array(sln_projects),
    }, "build_system_meta_build_sln")

    sln_projects[#sln_projects + 1] = regen_meta_proj
    sln_projects[#sln_projects + 1] = meta_proj
    projects[#projects + 1]         = meta_proj

    -- workspacename will show up in Codelite and is used as the base name for the database file
    -- so we don't want the extension to be part of it
    local first, last = name:find(proj_extension)
    local workspacename
    if first and first > 1 then
      workspacename = name:sub(1, first - 1)
    else
      workspacename = name
    end

    solutions[#solutions + 1] = {
      Workspacename        = workspacename,
      Filename             = base_dir .. workspacename .. "_sln" .. proj_extension,
      Projects             = sln_projects,
      ExternalProjects     = ext_projects,
      BuildSolutionProject = meta_proj
    }
  end

  return solutions, projects
end


function qtcreator_generator:generate_solution(fn, projects, ext_projects, solution)
    local sln = io.open(fn .. '.tmp', 'wb')

  sln:write("TEMPLATE = subdirs", LF)
  sln:write("SUBDIRS += \\", LF)

  -- Map folder names to array of projects under that folder
  local sln_folders = {}
  for _, proj in ipairs(projects) do
    local hints = proj.IdeGenerationHints
    local qtcreator_hints = hints and hints.QtCreator or nil
    local folder = qtcreator_hints and qtcreator_hints.SolutionFolder or nil
    if folder then
      local projects = sln_folders[folder] or {}
      projects[#projects + 1] = proj
      sln_folders[folder] = projects
    end

    local name = folder or proj.Name
    if (_ < #projects) then
      sln:write("\t ", name, " \\", LF)
    else
      sln:write("\t ", name, LF)
    end
  end
  sln:write(LF)

  sln:close()

  ide_com.replace_if_changed(fn .. ".tmp", fn)

  -- .shared file, needed to make use of Tundra
  p = assert(io.open(fn .. ".shared.tmp", 'wb'))

  p:write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", LF)
  p:write("<!DOCTYPE QtCreatorProject>", LF)
  p:write("<!-- Written by Tundra for QtCreator 4. -->", LF)
  p:write("<qtcreator>", LF)
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.ActiveTarget</variable>", LF)
  p:write("  <value type=\"int\">0</value>", LF)
  p:write(" </data>", LF)
  write_editor_settings_plugin_settings(p)
  self:write_build_steps(p, projects)
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.TargetCount</variable>", LF)
  p:write("  <value type=\"int\">1</value>", LF)
  p:write(" </data>", LF)
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.Updater.FileVersion</variable>", LF)
  p:write("  <value type=\"int\">22</value>", LF)
  p:write(" </data>", LF)
  p:write(" <data>", LF)
  p:write("  <variable>Version</variable>", LF)
  p:write("  <value type=\"int\">22</value>", LF)
  p:write(" </data>", LF)
  p:write("</qtcreator>", LF)

  p:close()
  ide_com.replace_if_changed(fn .. ".shared.tmp", fn .. ".shared")
end


local function qtcreator_project_type(pt)

    local template_type = "app"
    local qtcreator_cfg = "console"

  if type(pt) == "string" then
    if pt == "StaticLibrary" then
      template_type = "lib"
      qtcreator_cfg = "staticlib"
    elseif pt == "SharedLibrary" then
      template_type = "lib"
      qtcreator_cfg = "dynamiclib"
    elseif pt == "Program" then
      template_type = "app"
      qtcreator_cfg = "console"
    else
      -- treat CSharp projects, ExternalLibrary and ObjGroup as non-code projects
      project_type  = "lib"
      qtcreator_cfg = "console"
    end
  end
  return template_type, qtcreator_cfg
end


function qtcreator_generator:generate_project(project, env)
  local cwd = native.getcwd()
  local fn  = project.Filename
  local p   = assert(io.open(fn .. ".tmp", 'wb'))
  local template_type = ""
  local qtcreator_cfg = ""

  if project.Unit then
    template_type, qtcreator_cfg = qtcreator_project_type(project.Unit.Keyword)
  end

  -- split project.Sources into src + header files
  local source_files = {}
  local header_files = {}
  local other_files  = {}

  -- @todo fetch this list from env or unit
  local cxx_exts = util.make_lookup_table {
    ".c", ".cpp", ".cxx", ".cc", ".m"
  }
  
  for _, filename in ipairs(project.Sources) do
    local fn = filename
    if not path.is_absolute(filename.Path) then
      fn = native.getcwd() .. SEP .. filename.Path
    end

    local ext = path.get_extension(filename.Path)
    if (ide_com.header_exts[ext]) then
      header_files[#header_files + 1] = fn
    elseif cxx_exts[ext] then
      source_files[#source_files + 1] = fn
    else
      other_files[#other_files + 1] = fn
    end
  end

  p:write("TEMPLATE = ", template_type, LF)
  p:write("TARGET = ", project.Name, LF)
  p:write("CONFIG = ", qtcreator_cfg, LF)
  p:write(LF)

  local function print_file_list(name, file_list)
    p:write(name, " += \\", LF)
    
    for k, v in ipairs(file_list) do
      if (k < #file_list) then
        p:write("\t", v, " \\", LF)
      else
        p:write("\t", v, LF)
      end
    end
    end

  if #source_files > 0 then
    print_file_list("SOURCES", source_files)
    p:write(LF)
  end
  
  if #other_files > 0 then
    print_file_list("DISTFILES", other_files)
    p:write(LF)
  end

  -- get include paths
  local include_paths = {}
  local defines       = {}
  for _, tuple in ipairs(self.config_tuples) do -- this will probably give us duplicates, different configs usually share most, if not all, include paths; we'll fix this further down
    local dag_node = ide_com.find_dag_node_for_config(project, tuple)
    if dag_node then
      --local env = dag_node.src_env
      local paths = util.map(env:get_list("CPPPATH"), function (p)
        local ip = path.normalize(env:interpolate(p))
        if not path.is_absolute(ip) then
          ip = native.getcwd() .. SEP .. ip
        end
        return ip
      end)
      util.append_table(include_paths, paths)

      local ext_paths = env:get_external_env_var('INCLUDE')
      if ext_paths then
        local extpaths = ext_paths:split(";")
        util.append_table(include_paths, extpaths)
      end
      if env:has_key("CPPDEFS") then
        local defs = env:get_list("CPPDEFS")
        util.append_table(defines, defs)
      end
    end
  end

  if project.Unit and project.Unit.Decl and project.Unit.Decl.Env and project.Unit.Decl.Env.CPPPATH then
    util.append_table(include_paths, project.Unit.Decl.Env.CPPPATH)
  end

  -- now that we have all include paths, remove the duplicates
  local includes = {}
  local unique_includes = {}
  for k, v in ipairs(include_paths) do
    if not unique_includes[v] then
      includes[#includes + 1] = v
      unique_includes[v] = true
    end
  end
  include_paths = includes

  if #include_paths > 0 then
    print_file_list("INCLUDEPATH", include_paths)
    p:write(LF)
  end

  if #header_files > 0 then
    print_file_list("HEADERS", header_files)
    p:write(LF)
  end

  if #defines > 0 then
    print_file_list("DEFINES", defines)
    p:write(LF)
  end

  p:close()
  ide_com.replace_if_changed(fn .. ".tmp", fn)

  -- .user file, needed to make use of Tundra
  fn  = project.Filename .. ".shared"
  p   = assert(io.open(fn .. ".tmp", 'wb'))

  p:write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", LF)
  p:write("<!DOCTYPE QtCreatorProject>", LF)
  p:write("<!-- Written by Tundra for QtCreator 4. -->", LF)
  p:write("<qtcreator>", LF)
  write_editor_settings_plugin_settings(p)
  local tmp_projects = {}
  tmp_projects[1] = project
  self:write_build_steps(p, tmp_projects, project.Name)
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.TargetCount</variable>", LF)
  p:write("  <value type=\"int\">1</value>", LF)
  p:write(" </data>", LF)
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.Updater.FileVersion</variable>", LF)
  p:write("  <value type=\"int\">22</value>", LF)
  p:write(" </data>", LF)
  p:write(" <data>", LF)
  p:write("  <variable>Version</variable>", LF)
  p:write("  <value type=\"int\">22</value>", LF)
  p:write(" </data>", LF)
  p:write("</qtcreator>", LF)

  p:close()

  ide_com.replace_if_changed(fn .. ".tmp", fn)
end


function qtcreator_generator:generate_files(ngen, config_tuples, raw_nodes, env, default_names, hints, ide_script)
  assert(config_tuples and #config_tuples > 0)

  if not hints then
    hints = {}
  end

  local complained_mappings = {}

    local qtcreator_hints = hints.QtCreator or {}

  local variant_mappings    = qtcreator_hints.VariantMappings    or {}
  local platform_mappings   = qtcreator_hints.PlatformMappings   or {}
  local subvariant_mappings = qtcreator_hints.SubVariantMappings or {}

  local friendly_names = {}

  for _, tuple in ipairs(config_tuples) do

    local friendly_name       = platform_mappings[tuple.Config.Name]  or tuple.Config.Name
    local friendly_variant    = variant_mappings[tuple.Variant.Name]  or tuple.Variant.Name
    local friendly_subvariant = subvariant_mappings[tuple.SubVariant] or tuple.SubVariant

    if #friendly_name == 0 then
      friendly_name = friendly_variant
    elseif #friendly_variant > 0 then -- Variant should not be empty, catch anyway
      friendly_name = friendly_name .. "-" .. friendly_variant
    end

    if #friendly_name == 0 then
      friendly_name = friendly_subvariant
    elseif #friendly_subvariant > 0 then
      friendly_name = friendly_name .. "-" .. friendly_subvariant
    end

    -- sanity check
    if #friendly_name == 0 then
      friendly_name = tuple.Config.Name .. '-' .. tuple.Variant.Name .. '-' .. tuple.SubVariant
    end

    if friendly_names[friendly_name] then
      print("WARNING: friendly name '" .. friendly_name .. "' is not unique!")
    end
    friendly_names[friendly_name] = true

    tuple.QtCreatorConfiguration = friendly_name
  end

  self.config_tuples = config_tuples

  printf("Generating Codelite projects for %d configurations/variants", #config_tuples)

  -- Figure out where we're going to store the projects
  local solutions, projects = make_project_data(raw_nodes, env, ".pro", hints, ide_script)

  local proj_lut = {}
  for _, p in ipairs(projects) do
    proj_lut[p.Name] = p
  end

  for _, sln in pairs(solutions) do
    self:generate_solution(sln.Filename, sln.Projects, sln.ExternalProjects, sln)
  end

  for _, proj in ipairs(projects) do
    self:generate_project(proj, env)
  end
end


local function write_run_section(p, proj, program_idx, root_dir)
  p:write("   <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.Target.RunConfiguration.", program_idx, "\">", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.QmlProfiler.AggregateTraces\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.QmlProfiler.FlushEnabled\">false</value>", LF)
  p:write("    <value type=\"uint\" key=\"Analyzer.QmlProfiler.FlushInterval\">1000</value>", LF)
  p:write("    <value type=\"QString\" key=\"Analyzer.QmlProfiler.LastTraceFile\"></value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.QmlProfiler.Settings.UseGlobalSettings\">true</value>", LF)
  p:write("    <valuelist type=\"QVariantList\" key=\"Analyzer.Valgrind.AddedSuppressionFiles\"/>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.Callgrind.CollectBusEvents\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.Callgrind.CollectSystime\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.Callgrind.EnableBranchSim\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.Callgrind.EnableCacheSim\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.Callgrind.EnableEventToolTips\">true</value>", LF)
  p:write("    <value type=\"double\" key=\"Analyzer.Valgrind.Callgrind.MinimumCostRatio\">0.01</value>", LF)
  p:write("    <value type=\"double\" key=\"Analyzer.Valgrind.Callgrind.VisualisationMinimumCostRatio\">10</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.FilterExternalIssues\">true</value>", LF)
  p:write("    <value type=\"int\" key=\"Analyzer.Valgrind.LeakCheckOnFinish\">1</value>", LF)
  p:write("    <value type=\"int\" key=\"Analyzer.Valgrind.NumCallers\">25</value>", LF)
  p:write("    <valuelist type=\"QVariantList\" key=\"Analyzer.Valgrind.RemovedSuppressionFiles\"/>", LF)
  p:write("    <value type=\"int\" key=\"Analyzer.Valgrind.SelfModifyingCodeDetection\">1</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.Settings.UseGlobalSettings\">true</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.ShowReachable\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"Analyzer.Valgrind.TrackOrigins\">true</value>", LF)
  p:write("    <value type=\"QString\" key=\"Analyzer.Valgrind.ValgrindExecutable\">valgrind</value>", LF)
  p:write("    <valuelist type=\"QVariantList\" key=\"Analyzer.Valgrind.VisibleErrorKinds\">", LF)
  for idx = 0,14,1 do
    p:write("     <value type=\"int\">" .. tostring(idx) .. "</value>", LF)
  end
  p:write("    </valuelist>", LF)
  p:write("    <value type=\"int\" key=\"PE.EnvironmentAspect.Base\">2</value>", LF)
  p:write("    <valuelist type=\"QVariantList\" key=\"PE.EnvironmentAspect.Changes\"/>", LF)
  p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">", proj.Name, "</value>", LF)
  p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\"></value>", LF)
  p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">Qt4ProjectManager.Qt4RunConfiguration:", root_dir .. proj.Filename, "</value>", LF)
  p:write("    <value type=\"bool\" key=\"QmakeProjectManager.QmakeRunConfiguration.UseLibrarySearchPath\">true</value>", LF)
  p:write("    <value type=\"QString\" key=\"Qt4ProjectManager.Qt4RunConfiguration.CommandLineArguments\"></value>", LF)
  p:write("    <value type=\"QString\" key=\"Qt4ProjectManager.Qt4RunConfiguration.ProFile\">", proj.Name .. SEP .. proj.Name .. ".pro</value>", LF) -- can be wrong, should use hints
  p:write("    <value type=\"bool\" key=\"Qt4ProjectManager.Qt4RunConfiguration.UseDyldImageSuffix\">false</value>", LF)
  p:write("    <value type=\"QString\" key=\"Qt4ProjectManager.Qt4RunConfiguration.UserWorkingDirectory\"></value>", LF)
  p:write("    <value type=\"QString\" key=\"Qt4ProjectManager.Qt4RunConfiguration.UserWorkingDirectory.default\">", root_dir, "</value>", LF)
  p:write("    <value type=\"uint\" key=\"RunConfiguration.QmlDebugServerPort\">3768</value>", LF)
  p:write("    <value type=\"bool\" key=\"RunConfiguration.UseCppDebugger\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"RunConfiguration.UseCppDebuggerAuto\">true</value>", LF)
  p:write("    <value type=\"bool\" key=\"RunConfiguration.UseMultiProcess\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"RunConfiguration.UseQmlDebugger\">false</value>", LF)
  p:write("    <value type=\"bool\" key=\"RunConfiguration.UseQmlDebuggerAuto\">true</value>", LF)
  p:write("   </valuemap>", LF)
end


function qtcreator_generator:write_build_steps(p, projects, build_project)
  p:write(" <data>", LF)
  p:write("  <variable>ProjectExplorer.Project.Target.0</variable>", LF)
  p:write("  <valuemap type=\"QVariantMap\">", LF)
  p:write("   <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">Desktop</value>", LF)
  p:write("   <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\">Desktop</value>", LF)
  p:write("   <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">{44ab07e5-d72d-467c-b24a-94d1906a5473}</value>", LF)
  p:write("   <value type=\"int\" key=\"ProjectExplorer.Target.ActiveBuildConfiguration\">0</value>", LF)
  p:write("   <value type=\"int\" key=\"ProjectExplorer.Target.ActiveDeployConfiguration\">0</value>", LF)
  p:write("   <value type=\"int\" key=\"ProjectExplorer.Target.ActiveRunConfiguration\">0</value>", LF)

  local root_dir = native.getcwd()
  local base     = "-C " .. root_dir .. " "
  for idx, tuple in ipairs(self.config_tuples) do
    local build_id    = string.format("%s-%s-%s", tuple.Config.Name, tuple.Variant.Name, tuple.SubVariant)
    local build_cmd   = base .. build_id
    local clean_cmd   = base .. "--clean " .. build_id
    -- rebuild seems to be handled internally, QtCreator is not offering a build step for it

    if build_project then
      build_cmd = build_cmd .. " " .. build_project
      clean_cmd = clean_cmd .. " " .. build_project
    end

    p:write("   <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.Target.BuildConfiguration." .. idx - 1 .. "\">", LF)
    p:write("    <value type=\"QString\" key=\"ProjectExplorer.BuildConfiguration.BuildDirectory\">", root_dir, SEP, "t2-output", SEP, build_id, "</value>", LF)
    -- build
    p:write("    <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.BuildConfiguration.BuildStepList.0\">", LF)
    p:write("     <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.BuildStepList.Step.0\">", LF)
    p:write("      <value type=\"bool\" key=\"ProjectExplorer.BuildStep.Enabled\">true</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProcessStep.Arguments\">", build_cmd, "</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProcessStep.Command\">", TundraExePath, "</value>", LF) -- QtCreator chokes on escaped paths
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProcessStep.WorkingDirectory\">", root_dir, "</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">Custom Process Step</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\">Tundra Build</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">ProjectExplorer.ProcessStep</value>", LF)
    p:write("     </valuemap>", LF)
    p:write("     <value type=\"int\" key=\"ProjectExplorer.BuildStepList.StepsCount\">1</value>", LF)
    p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">Build</value>", LF)
    p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\">Build</value>", LF)
    p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">ProjectExplorer.BuildSteps.Build</value>", LF)
    p:write("    </valuemap>", LF)
    -- clean
    p:write("    <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.BuildConfiguration.BuildStepList.1\">", LF)
    p:write("     <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.BuildStepList.Step.0\">", LF)
    p:write("      <value type=\"bool\" key=\"ProjectExplorer.BuildStep.Enabled\">true</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProcessStep.Arguments\">", clean_cmd, "</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProcessStep.Command\">", TundraExePath, "</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProcessStep.WorkingDirectory\">", root_dir, "</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">Custom Process Step</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\">Tundra Clean</value>", LF)
    p:write("      <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">ProjectExplorer.ProcessStep</value>", LF)
    p:write("     </valuemap>", LF)
    p:write("     <value type=\"int\" key=\"ProjectExplorer.BuildStepList.StepsCount\">1</value>", LF)
    p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">Clean</value>", LF)
    p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\">Clean</value>", LF)
    p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">ProjectExplorer.BuildSteps.Clean</value>", LF)
    p:write("    </valuemap>", LF)
    p:write("    <value type=\"int\" key=\"ProjectExplorer.BuildConfiguration.BuildStepListCount\">2</value>", LF)
    p:write("    <value type=\"bool\" key=\"ProjectExplorer.BuildConfiguration.ClearSystemEnvironment\">false</value>", LF)
    p:write("    <valuelist type=\"QVariantList\" key=\"ProjectExplorer.BuildConfiguration.UserEnvironmentChanges\"/>", LF)
    p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">".. tuple.QtCreatorConfiguration .. "</value>", LF)
    p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\"></value>", LF)
    p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">Qt4ProjectManager.Qt4BuildConfiguration</value>", LF)
    p:write("    <value type=\"int\" key=\"Qt4ProjectManager.Qt4BuildConfiguration.BuildConfiguration\">", idx - 1, "</value>", LF)
    p:write("    <value type=\"bool\" key=\"Qt4ProjectManager.Qt4BuildConfiguration.UseShadowBuild\">true</value>", LF)
    p:write("   </valuemap>", LF)
  end
  p:write("   <value type=\"int\" key=\"ProjectExplorer.Target.BuildConfigurationCount\">" .. #self.config_tuples .. "</value>", LF)

  -- Deployment steps, empty for now
  p:write("   <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.Target.DeployConfiguration.0\">", LF)
  p:write("    <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.BuildConfiguration.BuildStepList.0\">", LF)
  p:write("     <value type=\"int\" key=\"ProjectExplorer.BuildStepList.StepsCount\">0</value>", LF)
  p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">Deploy</value>", LF)
  p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\"></value>", LF)
  p:write("     <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">ProjectExplorer.BuildSteps.Deploy</value>", LF)
  p:write("    </valuemap>", LF)
  p:write("    <value type=\"int\" key=\"ProjectExplorer.BuildConfiguration.BuildStepListCount\">1</value>", LF)
  p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DefaultDisplayName\">Deploy locally</value>", LF)
  p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.DisplayName\"></value>", LF)
  p:write("    <value type=\"QString\" key=\"ProjectExplorer.ProjectConfiguration.Id\">ProjectExplorer.DefaultDeployConfiguration</value>", LF)
  p:write("   </valuemap>", LF)
  p:write("   <value type=\"int\" key=\"ProjectExplorer.Target.DeployConfigurationCount\">1</value>", LF)
  p:write("   <valuemap type=\"QVariantMap\" key=\"ProjectExplorer.Target.PluginSettings\"/>", LF)

  -- run
  local program_idx = 0
  for _, proj in ipairs(projects) do
    if not proj.IsMeta and proj.Unit.Keyword == "Program" then
      write_run_section(p, proj, program_idx, root_dir)
      program_idx = program_idx + 1
    end
  end
  p:write("   <value type=\"int\" key=\"ProjectExplorer.Target.RunConfigurationCount\">", program_idx, "</value>", LF)
  p:write("  </valuemap>", LF)
  p:write(" </data>", LF)
end
