function initialize_argo(root_dir)
% initialize_argo  This function is part of the
% MATLAB toolbox for accessing EasyOneArgoBGC float data.
%
% USAGE:
%   initialize_argo()
%
% DESCRIPTION:
%   This function defines standard settings and paths and downloads
%   index files. It must be called once before any other functions
%   can be used, either directly or indirectly by calling any of
%   the functions load_float_data, select_profiles, show_profiles,
%   show_sections, or show_trajectories.
%
% INPUT: None
%
% OPTIONAL INPUT:
%   root_dir : root path for the toolbox to use (default: current directory)
%
% OUTPUT: None
%   Global variables Settings and Index are defined.
%
% AUTHOR:
%   H. Frenzel (UW-CICOES)
%
% LICENSE: easyoneargo_mat_license.m
%
% DATE: AUGUST 16, 2026  (Version 0.1)

global Settings Index;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BEGINNING OF SECTION WITH USER SPECIFIC OPTIONS
% this part of the function can be modified to meet specific needs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The do_pause() function can be used in a driver script to
% halt the execution until the user presses ENTER.
% Set Settings.use_pause to 0 if you want to run everything without stopping.
use_desktop = desktop('-inuse');
%Settings.use_pause = ~use_desktop; % best setting for standard use
Settings.use_pause = 1; % best setting for Tutorial

% By default, actively running commands are described with output
% to the command window. Set this to 0 to suppress this output.
% Values larger than 1 can be used to help in debugging.
Settings.verbose = 1;

% Maximum number of plots that can be created with one call to
% show_profiles etc.
% Increase this number if necessary, if you are sure that
% your system can handle it.
Settings.max_plots = 20;

if nargin < 1
    root_dir = './';
end
if endsWith(root_dir, '/')
    slash = '';
else
    slash = '/';
end
% index files, either at the GDAC or in a snapshot
index_prof = sprintf('%s%sEasyOneArgoBGCLite/EasyOneArgoBGCLite_index.csv', ...
    root_dir, slash);

if ~exist(index_prof, 'file')
    disp('Please download the most recent snapshot of EasyOneArgoBGCLite')
    disp('from https://www.seanoe.org/data/00961/107233')
    fprintf('and place it into %s%sEasyOneArgoBGCLite\n', root_dir, slash)
    return
end


Settings.demo_float = 5904021;

% default values for computation of mixed layer depth
Settings.temp_thresh = 0.2;
Settings.dens_thresh = 0.03;

% default value for deviation from requested depth level for time series
% plots - if exceeded, a warning will be issued
Settings.depth_tol = 5;

% Settings.colormap = 'jet'; % uncomment and change as needed

% colors for profile plots ("range" is for individual profiles using the
% 'all' method and mean +- std.dev. in the 'mean' method)
Settings.color_var1_mean = [0, 0, 0]; % black
Settings.color_var1_range = [0.7 0.7 0.7]; % light gray
Settings.color_var2_mean = [0, 0, 1]; % blue
Settings.color_var2_range = [0.5, 0.75, 1]; % light blue

% color for estimated locations in trajectory plots
Settings.color_estim_loc = [0.7 0.7 0.7]; % light gray

% colors for data modes in trajectory plots:
% blue for R, yellow for A, green for D
Settings.traj_mode_colors = {[0, 0.4470, 0.7410]; ...
    [0.9290, 0.6940, 0.1250]; [0.4660, 0.6740, 0.1880]};

% amount of lon/lat padding in trajectory plots (in degrees)
Settings.pad_lon = 5;
Settings.pad_lat = 5;

% Default: do not interpolate missing lon/lat values
Settings.interp_lonlat = 'no';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END OF SECTION WITH USER SPECIFIC OPTIONS
% the rest of this function should not be modified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add subdirectories with auxiliary functions to the path
filepath = fileparts(mfilename('fullpath'));
addpath([filepath, '/auxil'])
addpath(genpath([filepath, '/m_map']))
addpath(genpath([filepath, '/gsw']))

% List of Data Assimilation Centers
%Settings.dacs = {'aoml'; 'bodc'; 'coriolis'; 'csio'; 'csiro'; 'incois'; ...
%    'jma'; 'kma'; 'kordi'; 'meds'; 'nmdis'};

Settings.data = {'PRES';'TEMP';'PSAL';'DOXY';'NITRATE';'PH_IN_SITU_TOTAL'; ...
    'CHLA';'FLUORESCENCE_CHLA';'BBP700';'DOWN_IRRADIANCE380'; ...
    'DOWN_IRRADIANCE412';'DOWN_IRRADIANCE443';'DOWN_IRRADIANCE490'; ...
    'DOWN_IRRADIANCE555';'DOWNWELLING_PAR'};

% Read the index file
opts = detectImportOptions(index_prof);
opts = setvaropts(opts, "platform_number", "Type", "int32");
opts = setvaropts(opts, "profile_date", "Type", "datetime");
opts = setvaropts(opts, "profile_date", "InputFormat", "yyyy-MM-dd'T'HH:mm:ssX");
opts = setvaropts(opts, "profile_date", "TimeZone", "UTC");
argo_table = readtable(index_prof, opts);
Settings.dacs_short = unique(argo_table.data_centre);
Index.wmoid = unique(argo_table.platform_number);

num_dacs = length(Settings.dacs_short);
num_floats = length(Index.wmoid);
num_profiles = height(argo_table);

new_cols = array2table(char(argo_table.data_mode), 'VariableNames', Settings.data);
Index.argo_table = [argo_table, new_cols];

disp('Index table was read successfully')
fprintf('There are %d profiles from %d floats.\n', num_profiles, num_floats)

% Determine the availability of mapping functions
if ~isempty(which('geobasemap'))
    Settings.mapping = 'native';
elseif ~isempty(which('m_proj'))
    Settings.mapping = 'm_map';
else
    Settings.mapping = 'plain';
end

Settings.root_dir = root_dir;

