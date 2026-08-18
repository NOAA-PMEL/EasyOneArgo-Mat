# EasyOneArgo-Mat
Matlab code for accessing EasyOneArgo data

This is a very early alpha version with very limited functionality for BGC data only.

Steps:

1. Clone this repo to your computer
2. From https://www.seanoe.org/data/00961/107233/, download the latest EasyOneArgoBGCLite archive and unpack it.
3. In the directory that holds initialize_argo.m etc., create a directory EasyOneArgoBGCLite
4. Move file EasyOneArgoBGCLite_index.csv and directory data from the archive into directory EasyOneArgoBGCLite
5. Start Matlab
6. Run initialize_argo
7. Use function select_profiles to select floats and profiles by geographic and/or time limits, sensor type (e.g., DOXY), and/or the minimum number of profiles meeting the other criteria.
8. Function show_trajectories can be used to show the trajectories of one or more floats by their WMO IDs, as returned from function select_profiles.
