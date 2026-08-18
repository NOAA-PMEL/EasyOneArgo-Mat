function good_float_ids = show_trajectories(float_ids,varargin)
% show_trajectories  This function is part of the
% MATLAB toolbox for accessing EasyOneArgo float data.
%
% USAGE:
%   good_float_ids = show_trajectories(float_ids,varargin)
%
% DESCRIPTION:
%
% INPUT:
%   float_ids : WMO ID(s) of one or more floats
%
% OPTIONAL INPUTS:
%   'color',color : color (string) can be either 'multiple' (different
%                   colors for different floats), or any standard Matlab
%                   color descriptor ('r', 'k', 'b', 'g' etc.)
%                   (all trajectories will be plotted in the same color);
%                   default value is 'multiple';
%   'float_profs',fp : fp is an array with the per-float indices of the
%                   selected profiles, as returned by function
%                   select_profiles - use this optional argument if you
%                   don't want to plot the full trajectories of the
%                   given floats, but only those locations that match
%                   spatial and/or temporal constraints
%   'png',fn_png  : save the plot to a png file with the given
%
% OUTPUT:
%   good_float_ids : array of the float IDs whose data exist in the current
%                    snapshot
% AUTHOR:
%   H. Frenzel (UW-CICOES)
%
% CITATION:
%
% LICENSE: easyoneargo_mat_license.m
%
% DATE: 

global Index Settings;

% make sure Index is initialized
if isempty(Index)
    initialize_argo();
end

if ~nargin
    float_ids = Settings.demo_float;
end

% set defaults
color = 'multiple';
float_profs = [];
pos = [];
fn_png = [];
title = 'Float trajectories';
lines = 'no';
lgnd = 'yes';
sz = 36;
mark_estim = 'no';
interp_lonlat = Settings.interp_lonlat;
sensor = [];

% parse optional arguments
for i = 1:2:length(varargin)-1
    if strcmpi(varargin{i}, 'color')
        color = varargin{i+1};
    elseif strcmpi(varargin{i}, 'float_profs')
        float_profs = varargin{i+1};
    elseif strcmpi(varargin{i}, 'position')
        pos = varargin{i+1};
    elseif strcmpi(varargin{i}, 'png')
        fn_png = varargin{i+1};
    elseif strcmpi(varargin{i}, 'title')
        title = varargin{i+1};
    elseif strcmpi(varargin{i}, 'lines')
        lines = varargin{i+1};
    elseif strcmpi(varargin{i}, 'legend')
        lgnd = varargin{i+1};
    elseif strcmpi(varargin{i}, 'size')
        if round(varargin{i+1}) > 0
            sz = round(varargin{i+1});
        else
            warning('size must be a positive integer')
        end
    elseif strcmpi(varargin{i}, 'mark_estim')
        mark_estim = varargin{i+1};
    elseif strcmpi(varargin{i}, 'interp_lonlat')
        interp_lonlat = varargin{i+1};
    elseif strcmpi(varargin{i}, 'sensor')
        sensor = varargin{i+1};
    else
        warning('unknown option: %s', varargin{i});
    end
end

if strcmp(color, 'mode') && isempty(sensor)
    warning('sensor must be specified for "mode" colors')
    return;
end

% make sure that all requested float_ids are available
good_float_ids = intersect(float_ids, Index.wmoid);
bad_float_ids = setdiff(float_ids, good_float_ids);

if ~isempty(bad_float_ids)
    warning('These floats are not present in the data:')
    disp(bad_float_ids)
end

if isempty(good_float_ids)
    warning('no valid floats found')
    return
end

% determine lon/lat limits for requested floats
all_lon = Index.argo_table{ismember(Index.argo_table.platform_number, ...
    good_float_ids), 'profile_longitude'};
all_lat = Index.argo_table{ismember(Index.argo_table.platform_number, ...
    good_float_ids), 'profile_latitude'};

lon_lim = [min(all_lon), max(all_lon)];
lat_lim = [min(all_lat), max(all_lat)];

% use "geoscatter" as default
if strcmp(Settings.mapping, 'native')
    geoaxes;
    hold on;
    % Set geographic limits for figure
    geolimits(lat_lim,lon_lim)
    geobasemap grayland
    for f = 1:length(good_float_ids)
        geoscatter(Index.argo_table{Index.argo_table.platform_number == ...
            good_float_ids(f), 'profile_latitude'}, ...
            Index.argo_table{Index.argo_table.platform_number == ...
            good_float_ids(f), 'profile_longitude'}, sz, '.');
    end
    hold off
    keyboard
    legend(string(good_float_ids), 'Location', 'eastoutside')
    title('Float trajectories')
else
    warning('only geoscatter is implemented for now')
end


