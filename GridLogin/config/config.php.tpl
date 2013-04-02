<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

/*
|--------------------------------------------------------------------------
| Service URLs
|--------------------------------------------------------------------------
|
| Enter the URL of each SimianGrid service below
|
*/
$config['user_service'] = "@@USER_SERVICE@@";
$config['grid_service'] = "@@GRID_SERVICE@@";
$config['asset_service'] = "@@ASSET_SERVICE@@";
$config['inventory_service'] = "@@INVENTORY_SERVICE@@";
$config['map_service'] = "@@MAP_SERVICE@@";

/*
|--------------------------------------------------------------------------
| Hypergrid Service URLs
|--------------------------------------------------------------------------
|
| By default these are equivalent to the service URLs. However, the host name
| must be an external hostname. Override if you use "localhost" for your 
| service URLs
|
*/
$config['hg_user_service'] = $config['user_service'];
$config['hg_asset_service'] = $config['asset_service'];
$config['hg_inventory_service'] = $config['inventory_service'];
$config['hypergrid_uri'] = $config['grid_service'] . 'hypergrid.php';

//Default Region for HG
$config['hypergrid_default_region'] = "OpenSim Test";

/*
|--------------------------------------------------------------------------
| Error Logging Threshold
|--------------------------------------------------------------------------
|
| You can enable error logging by setting a threshold over zero. The
| threshold determines what gets logged. Threshold options are:
|
|	0 = Disables logging, Error logging TURNED OFF
|	1 = Error Messages (including PHP errors)
|   2 = Warning Messages
|	3 = Informational Messages
|	4 = Debug Messages
|
| For a live site you'll usually only enable Errors (1) to be logged otherwise
| your log files will fill up very fast.
|
*/
$config['log_threshold'] = 1;

/*
|--------------------------------------------------------------------------
| Error Logging Directory Path
|--------------------------------------------------------------------------
|
| Leave this BLANK unless you would like to set something other than the default
| logs/ folder. Use a full server path with trailing slash.
|
*/
$config['log_path'] = "";

/*
|--------------------------------------------------------------------------
| Time Zone
|--------------------------------------------------------------------------
|
| You can change this to a PHP-supported timezone to write log files with
| your local timezone instead of UTC. http://php.net/manual/en/timezones.php
| has a list of supported timezone names.
|
*/
date_default_timezone_set("UTC");

/*
|--------------------------------------------------------------------------
| Date Format for Logs
|--------------------------------------------------------------------------
|
| Each item that is logged has an associated date. You can use PHP date
| codes to set your own date formatting
|
*/
$config['log_date_format'] = 'Y-m-d H:i:s';

/*
|--------------------------------------------------------------------------
| Default Location
|--------------------------------------------------------------------------
|
| Default location where users start if no other valid location is
| specified
|
*/
$config['default_location'] = "OpenSim Test/128/128/25";

/*
|--------------------------------------------------------------------------
| Library Owner
|--------------------------------------------------------------------------
|
| Configure a grid-wide asset library. If you specify the name or UUID of an
| avatar, that avatar's inventory will be exported as the library. If no
| library path is defined, the entire inventory will be exported. Otherwise,
| just items in the path will be exported.
|
| Specifying the owner by uuid or the folder by uuid will improve 
| performance marginally.
|
*/
$config['library_owner_id'] = "ba2a564a-f0f1-4b82-9c61-b7520bfcd09f";
//$config['library_owner_name'] = "Library TestUser";
//$config['library_folder_id'] = "/Grid Library";
//$config['library_folder_path'] = "";

