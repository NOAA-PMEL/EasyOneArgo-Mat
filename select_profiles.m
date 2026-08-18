function [float_ids, float_profs, argo_table] = select_profiles(lon_lim,lat_lim,...
    start_date,end_date,varargin)
% select_profiles  This function is part of the
% MATLAB toolbox for accessing EasyOneArgoBBGC float data.
%
% USAGE:
%   argo_table = select_profiles(lon_lim,lat_lim,...
%       start_date,end_date,varargin)
%
% DESCRIPTION:
%   This function returns the rows of the index table that match all
%   specified criteria.
%
% INPUTS:
%   lon_lim : longitude limits
%   lat_lim : latitude limits
%            * Latitude and longitude limits can be input as either
%            two element vectors ([LON1 LON2], [LAT1 LAT2]) for maximum
%            and minimum limits, or as same-sized vectors with at least
%            3 elements for vertices of a polygon
%            * Longitude can be input in either the -180 to 180 degrees
%            format or 0 to 360 degrees format (or even in any other
%            360 degree range that encloses all the desired longitude
%            values, e.g., [-20 200] or [-200 20])
%            Note that [10 350] is NOT equivalent to [-10 10]:
%            the former results in a range of 340 degrees,
%            the latter in a range of 20 degrees.
%            * Either or both values can be '[]' to indicate the full range
%   start_date : start date
%   end_date : end date
%            * Dates should be in one of the following formats:
%            [YYYY MM DD HH MM SS] or [YYYY MM DD]
%            * Both values can be '[]' to indicate the full range
%
% OPTIONAL INPUTS (key,value pairs):
%   'cycles',cycles: Select profiles by their CYCLE_NUMBER values. cycles can
%           be a scalar or an array. Only floats that have at least one
%           of the specified cycles will be returned.
%   'dac',dac: Select by Data Assimilation Center reponsible for the floats.
%           A single DAC can be entered as a string (e.g.: 'AO'),
%           multiple DACs can NOT YET be entered as a cell array (e.g.:
%           {'ME';'IN'}. -- not yet implemented
%           Valid values are any of: {'AO'; 'BO'; 'CS'; ...
%           'HZ'; 'IF'; 'IN'; 'JA'; 'ME'}
%   'direction',dir: Select profiles by direction ('a' for ascending,
%           'd' for descending, '' for both directions)
%   'floats',floats: Select profiles only from these floats that must
%           match all other criteria
%   'max_depth',max_depth: Select profiles that reach at most this depth
%           (positive downwards; in db)
%   'min_depth',min_depth: Select profiles that reach at least this depth
%           (positive downwards; in db)
%   'min_num_prof',num_prof: Select only floats that have at least
%           num_prof profiles that meet all other criteria
%   'mode',mode: Valid modes are 'R' (real-time), 'A' (adjusted), and
%           'D', in any combination. Only profiles with the selected
%           mode(s) will be listed in float_profs.
%           Default is 'RAD' (all modes).
%           If multiple sensors are specified, all of them must be in
%           the selected mode(s).
%           If 'sensor' option is not used, the 'mode' option is ignored,
%           unless 'type','phys' is specified (for non-BGC floats,
%           pressure, temperature, and salinity are always in the same
%           mode).
%   'sensor', SENSOR_TYPE: This option allows the selection by
%           sensor type. Available are: PRES, PSAL, TEMP, DOXY, BBP,
%           BBP470, BBP532, BBP700, TURBIDITY, CP, CP660, CHLA, CDOM,
%           NITRATE, BISULFIDE, PH_IN_SITU_TOTAL, DOWN_IRRADIANCE,
%           DOWN_IRRADIANCE380, DOWN_IRRADIANCE412, DOWN_IRRADIANCE443,
%           DOWN_IRRADIANCE490, DOWN_IRRADIANCE555, DOWN_IRRADIANCE670,
%           UP_RADIANCE, UP_RADIANCE412, UP_RADIANCE443, UP_RADIANCE490,
%           UP_RADIANCE555, DOWNWELLING_PAR, CNDC, DOXY2, DOXY3, BBP700_2
%           (Full list can be displayed with the list_sensors function.)
%           Multiple sensors can NOT YET be entered as a cell array, e.g.:
%           {'DOXY';'NITRATE'}!! (feature not yet implemented; use multiple
%           calls to select_profiles with the 'floats' option to do this)
%
% OUTPUTS:
%   float_ids   : array with the WMO IDs of all matching floats
%   float_profs : cell array with the per-float indices of all matching profiles
%
% AUTHORS:
%   H. Frenzel (UW-CICOES)
%
% CITATION:
%
% LICENSE: easyoneargo_mat_license.m
%
% DATE: 

global Settings Index;

if nargin < 4
    disp('You must call select_profiles with lon_lim, lat_lim, start_date, end_date arguments')
    disp('You can use empty brackets for any or all of them.')
    warning('Not enough arguments')
    return
end

% make sure Index is initialized
if isempty(Index)
    initialize_argo();
end

% set defaults
float_ids = [];
float_profs = [];
outside = 'none'; % if set, removes profiles outside time/space constraints
sensor = []; % default: use all profiles that match other criteria
mode = 'RAD';
dac = [];
floats = [];
max_depth = [];
min_depth = [];
min_num_prof = 0;
interp_ll = Settings.interp_lonlat;
direction = '';
cycles = [];

% parse optional arguments
for i = 1:2:length(varargin)-1
    if strcmpi(varargin{i}, 'outside')
        outside = varargin{i+1};
    elseif strcmpi(varargin{i}, 'sensor')
        sensor = varargin{i+1};
    elseif strcmpi(varargin{i}, 'mode')
        mode = varargin{i+1};
    elseif strcmpi(varargin{i}, 'dac')
        dac = varargin{i+1};
    elseif strcmpi(varargin{i}, 'floats')
        floats = varargin{i+1};
    elseif strcmpi(varargin{i}, 'max_depth')
        max_depth = varargin{i+1};
    elseif strcmpi(varargin{i}, 'min_depth')
        min_depth = varargin{i+1};
    elseif strcmpi(varargin{i}, 'min_num_prof')
        min_num_prof = varargin{i+1};
    elseif strcmpi(varargin{i}, 'interp_lonlat')
        interp_ll = varargin{i+1};
    elseif strcmpi(varargin{i}, 'direction')
        direction = varargin{i+1};
    elseif strcmpi(varargin{i}, 'cycles')
        cycles = varargin{i+1};
    else
        warning('unknown option: %s', varargin{i});
    end
end

if ~isempty(min_depth) && ~isempty(max_depth) && max_depth < min_depth
    warning('The maximum depth must exceed the minimum depth')
    return
end

% convert requested sensor(s) to cell array if necessary and
% discard unknown sensors
%FIXME sensor = check_variables(sensor, 'warning', ...
%    'unknown sensor will be ignored');

% only use mode if sensor was specified
if ~strcmp(sort(mode), 'ADR') && isempty(sensor)
    warning('Since no ''sensor'' was specified, the mode will be ignored.')
    disp('All floats and profiles matching the other criteria will be selected.')
    pause(3);
    mode = [];
end

% check if specified data modes are correct
new_mode= '';
for i = 1:length(mode)
    if contains('RAD', mode(i))
        new_mode = strcat(new_mode, mode(i));
    else
        warning('no such mode: %s', mode(i))
    end
end
if isempty(new_mode)
    mode = 'ADR';
else
    mode = sort(new_mode); % standard order enables strcmp later
end

% check if specified dac(s) are correct
if ~ischar(dac)
    error('dac must be specified as a string')
end
% bad = zeros(length(dac), 1);
% for i = 1:length(dac)
%     if ~any(strcmp(dac{i}, Settings.dacs_short))
%         warning('no such dac: %s', dac{i});
%         bad(i) = 1;
%     end
% end
% dac(bad == 1) = [];

% check if specified direction is correct
if ~isempty(direction) && ~strncmpi(direction, 'a', 1) && ...
        ~strncmpi(direction, 'd', 1)
    warning('no such direction: %s', direction);
    direction = ''; % reset to "all"
end

% fill in the blanks if needed
if isempty(lon_lim)
    lon_lim = [-180, 180];
end
if isempty(lat_lim)
    lat_lim = [-90, 90];
end
if isempty(start_date)
    start_date = [1995, 1, 1];
end
if isempty(end_date)
    end_date = [2038, 1, 19];
end

% ADJUST INPUT DATES TO DATENUM FORMAT
dn1 = datenum(start_date);
dn2 = datenum(end_date);

if isempty(floats)
    argo_table = Index.argo_table;
else
    % filter out the selected floats before running other selections
    argo_table = Index.argo_table(ismember(Index.argo_table.platform_number, ...
        floats),:)
end

% successive filtering by criteria, starting with lon/lat
inpoly = get_inpolygon(argo_table.profile_longitude, ...
    argo_table.profile_latitude, lon_lim, lat_lim);
argo_table = argo_table(inpoly, :);

% next: time range
dt_start = datetime(start_date, 'TimeZone', 'UTC');
dt_end = datetime(end_date, 'TimeZone', 'UTC');
indate = argo_table.profile_date >= dt_start & ...
    argo_table.profile_date <= dt_end;
argo_table = argo_table(indate, :);

% and now by sensor
argo_table = argo_table(argo_table.(sensor) ~= '-', :);

% check for selected DACs if applicable (DACs are stored by float,
% not by profile)
if ~isempty(dac)
    argo_table(strcmp(argo_table.data_centre, dac), :);
end

% filter by cycle_number if specified
if ~isempty(cycles)
    argo_table = argo_table(ismember(argo_table.cycle_number, cycles), :);
end

% check for minimum number of profiles
if min_num_prof > 0
    float_ids = unique(argo_table.platform_number);
    valid_floats = arrayfun(@(x) sum(argo_table.platform_number == x) >= min_num_prof, float_ids);
    argo_table = argo_table(ismember(argo_table.platform_number, float_ids(valid_floats)), :);
end

float_ids = unique(argo_table.platform_number);

float_profs = arrayfun(@(x) find(argo_table.platform_number == x), float_ids, 'UniformOutput', false);
% Finalize the output by ensuring float_ids and float_profs are not empty
if isempty(float_ids)
    disp('No profiles found matching the specified criteria.');
    return;
end
