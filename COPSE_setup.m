function COPSE_setup
% Set up COPSE paths

% Add new directories to this list

paleodirs={'code','code/core','code/forcings', ...
    'code/copse', ...
    'code/configuration','code/utils',  ...
    'libraries/YAMLMatlab_0.4.3', ...
    'examples/copse'};

paleopath = pwd;

% get current path as semicolon-separated list
p = path;

% check for any PALEO or COPSE entries in current path

pentries = strsplit(p,pathsep);

pcopse = {};
for i = 1:length(pentries)
    if ~isempty(strfind(pentries{i},'PALEO')) || ~isempty(strfind(pentries{i},'COPSE'))
        pcopse{end+1} = pentries{i};
    end
end

% prompt user and remove any PALEO entries
% (eg if there are two installations ...)
if ~isempty(pcopse)
    fprintf('possible COPSE paths found\n');
    for i=1:length(pcopse)
           fprintf('         %s\n',pcopse{i})
    end
    
    str = input('\nRemove these paths ? Y/N [Y]\n','s');
    if isempty(str)
        str = 'Y';
    end
    if strcmpi(str,'Y')
        for i=1:length(pcopse)
            fprintf('removing folder %s\n',pcopse{i});
            rmpath(pcopse{i});
        end
    end
end

% Add PALEO paths

for i=1:length(paleodirs)
    psepdir = strrep(paleodirs{i},'/',filesep);
    fulldir = fullfile(paleopath,psepdir);
    fprintf('adding folder %s\n',fulldir);
    addpath(fulldir);
end
 
% Test yaml hence preload - attempt to workaround an issue on linux with crash ?

yaml_file = 'libraries/YAMLMatlab_0.4.3/Tests/Data/test_import/file1.yaml';
YamlStruct = ReadYaml(yaml_file);



