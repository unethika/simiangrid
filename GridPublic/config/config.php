<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

/*
|--------------------------------------------------------------------------
| Service URLs
|--------------------------------------------------------------------------
|
| Enter the URL of each SimianGrid service below
|
*/

$ExtHostName = gethostname();
$IntHostName = "localhost";
$RootPath = "Grid";

// This attempts to find the path to the Grid directory
$FullPath = substr(__FILE__,strlen($_SERVER['DOCUMENT_ROOT']));
if (preg_match('/\/.*\/Grid\//',$FullPath,$matches))
    $RootPath = trim($matches[0],'/');

$config['user_service'] = "http://$IntHostName/$RootPath/";
$config['grid_service'] = "http://$IntHostName/$RootPath/";
$config['asset_service'] = "http://$IntHostName/$RootPath/?id=";
$config['inventory_service'] = "http://$IntHostName/$RootPath/";
$config['map_service'] = "http://$ExtHostName/$RootPath/map/";


$config['hg_user_service'] = "http://$ExtHostName/$RootPath/";
$config['hg_asset_service'] = "http://$ExtHostName/$RootPath/?id=";
$config['hg_inventory_service'] = "http://$ExtHostName/$RootPath/";
$config['hypergrid_uri'] = strtolower("http://$ExtHostName/$RootPath/hypergrid.php");

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
$config['log_threshold'] = 5;
//$config['log_threshold'] = 2;

/*
|--------------------------------------------------------------------------
| Map Tile Directory Path
|--------------------------------------------------------------------------
|
| Leave this BLANK unless you would like to set something other than the default
| map/ folder. Use a full server path with trailing slash. This directory should
| map to the URL specified in $config['map_service'] above
|
*/
$config["map_path"] = "";

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
//$config['log_path'] = BASEPATH . 'logs/test/';

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
| Authorize Commands
|--------------------------------------------------------------------------
|
| Use capabilities to authorize commands, default is to authorize
| all operations regardless of the capability provided
|
*/
$config['authorize_commands'] = false;

