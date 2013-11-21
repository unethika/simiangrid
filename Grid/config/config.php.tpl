<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

/*
|--------------------------------------------------------------------------
| Database Connectivity Settings
|--------------------------------------------------------------------------
|
| The settings needed to access your database
|
*/
$config['db_hostname'] = "@@DB_HOST@@";
$config['db_username'] = "@@DB_USER@@";
$config['db_password'] = "@@DB_PASSWORD@@";
$config['db_database'] = "@@DB_NAME@@";
$config['db_driver'] = "mysql";
$config['db_prefix'] = "";
$config['db_persistent'] = TRUE;

// This is the number of days between updates to LastAccess for Assets
// and is useful if you want to clean up unused Assets from the Db
// 0 turns off all updates and is the old behavior
$config['access_update_interval'] = 0;


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
| Asset Driver
|--------------------------------------------------------------------------
|
| Select the inventory backend to use. Possible values:
|   SQLAssets - Database-backed asset backend.
|   MongoAssets - MongoDB-backed asset backend.
|
*/
$config['asset_driver'] = "SQLAssets";
//$config['asset_driver'] = "MongoAssets";
//$config['asset_driver'] = "FSAssets";

/* MongoDB server hostname and port number for the MongoAssets driver */
$config['mongo_server'] = "localhost:27017";
/* MongoDB database name */
$config['mongo_database'] = "SimianGrid";

/*
| FSAssets stores the asset data on the local filesystem.
| fsassets_path == where to store the asset data
*/
//$config['fsassets_path'] = "/srv/simiangrid/assets";

/*
|--------------------------------------------------------------------------
| Inventory Driver
|--------------------------------------------------------------------------
|
| Select the inventory backend to use. Possible values:
|   ALT - Adjacency List Table. A simple and fast database-backed inventory
|   MPTT - Modified Preorder Tree Table. An advanced database-backed
|          inventory optimized for read access. WORK IN PROGRESS.
|
*/
$config['inventory_driver'] = "ALT";
//$config['inventory_driver'] = "MPTT";

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
|	2 = Warning Messages
|	3 = Informational Messages
|	4 = Debug Messages, request times, response sizes
|       5 = Dump Every Request
|
| For a live site you'll usually only enable Errors (1) to be logged otherwise
| your log files will fill up very fast.
|
*/
$config['log_threshold'] = 1;

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

