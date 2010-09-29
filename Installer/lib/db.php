<?php if ( ! defined('BASEPATH') or !defined('SIMIAN_INSTALLER') ) exit('No direct script access allowed');
    function dbGetConfig()
    {
        $db_session = $_SESSION['db_config'];
        
        if ( $db_session != null ) {
            return $db_session;
        } else {
            global $defaultDB;
            return $defaultDB;
        }
    }
    
    function configGetDBValue($key) {
        $dbconf = dbGetConfig();
        if ( $key === "db_user" ) {
            return $dbconf['user'];
        } else if ( $key === "db_pass" ) {
            return $dbconf['password'];
        } else if ( $key === "db_host" ) {
            return $dbconf['host'];
        } else if ( $key === "db_name" ) {
            return $dbconf['db'];
        } else {
            return null;
        }
    }
    
    function dbConfigs()
    {
        $result = array();
        $dbconf = dbGetConfig();
        
        $result['db_user']['default'] = $dbconf['user'];
        $result['db_user']['string'] = "@@DB_USER@@";
        $result['db_pass']['default'] = $dbconf['password'];
        $result['db_pass']['string'] = "@@DB_PASSWORD@@";
        $result['db_name']['default'] = $dbconf['db'];
        $result['db_name']['string'] = "@@DB_NAME@@";
        $result['db_host']['default'] = $dbconf['host'];
        $result['db_host']['string'] = "@@DB_HOST@@";
        
        return $result;
    }
    
    function dbConfigValid()
    {
        $result = FALSE;
        
        $result['user'] = $_SESSION['db_config']['user'];
        $result['password'] = $_SESSION['db_config']['password'];
        $result['host'] = $_SESSION['db_config']['host'];
        $result['db'] = $_SESSION['db_config']['db'];
        
        if ( $user != null && $db != null ) {
            $result = TRUE;
        }
        return $result;
    }
    
    function dbProcessConfig()
    {
        $user = $_POST['user'];
        $password = $_POST['password'];
        $host = $_POST['host'];
        $db = $_POST['schema'];

        $result = array();
        if ( $user != null and $db != null ) {
            $result['user'] = $user;
            $result['db'] = $db;
            if ( $host != null ) {
                $result['host'] = $host;
            } else {
                $result['host'] = '127.0.0.1';
            }
            
            if ( $password != null ) {
                $result['password'] = $password;
            }
        }
        $_SESSION['db_config'] = $result;
        return $result;
    }

    function dbRequirementsMet()

    {
        if ( $_SESSION['db_version']['check'] === TRUE && $_SESSION['db_version']['db_check'] === TRUE ) {
            return TRUE;
        } else {
            return FALSE;
        }
    }
    
    function dbHandle()
    {    
        if ( ! isset($_SESSION['db_config']) ) {
            return FALSE;
        }
        $user = $_SESSION['db_config']['user'];
        $password = $_SESSION['db_config']['password'];
        $host = $_SESSION['db_config']['host'];
        error_reporting(E_ERROR);
        $db = mysqli_init();
        $check = mysqli_real_connect($db, $host, $user, $password);
        error_reporting(E_WARNING);
        if ( $check === FALSE ) {
            userMessage("error", "DB Error - " . mysqli_connect_error($db));
            return FALSE;
        }
        return $db;
    }
    
    function dbVersionCheck()
    {
        $db = dbHandle();
        $result = array();
        $result['required'] = MYSQL_VERSION;
        if ( ! $db ) {
            unset($_SESSION['db_version']);
            $result['connect'] = FALSE;
        } else {
            $result['connect'] = TRUE;
            $result['current'] = mysqli_get_server_info($db);
            #i wonder if version_compare is fine to use on mysql version numbers?
            $mysql_check = version_compare(MYSQL_VERSION, $result['current']);
            if ( $mysql_check <= 0 ) {
                $result['check'] = TRUE;
            } else {
                $result['check'] = FALSE;
            }
            $result['db_check'] = dbSelect($db);
            mysqli_close($db);
        }
        if ( ! isset($_SESSION['db_version']) ) {
            $_SESSION['db_version'] = array();
        }
        $_SESSION['db_version'] = array_merge($_SESSION['db_version'], $result);
        return $result;
    }
    
    function dbSelect($db)
    {
        if ( ! isset($_SESSION['db_config']) ) {
            return FALSE;
        }
        if ( $db === FALSE ) { 
            return FALSE;
        }
        $schema = $_SESSION['db_config']['db'];
        $check = mysqli_select_db($db, $schema);
        if ( $check === FALSE ) {
            userMessage("error", "Problem selecting database " . $schema . " - " . mysqli_error($db));
            return FALSE;
        } else {
            return dbEmpty($db);
        }
    }
    
    function dbListRelevantTables($db)
    {
        global $dbCheckTables;
        $result = mysqli_query($db, "SHOW TABLES");
        if ( ! $result ) {
            return FALSE;
        }
        $table_list = array();
        $schema  = $_SESSION['db_config']['db'];
        $table_key = "Tables_in_$schema";
        while ( $table = mysqli_fetch_assoc($result) ) {
            if ( array_search($table[$table_key], $dbCheckTables) !== FALSE ) {
                array_push($table_list, $table[$table_key]);
            }
        }
        return $table_list;

    }

    function dbComplete($tables)
    {
        global $dbCheckTables;
        $count = 0;
        foreach ( $tables as $table ) {
            if ( array_search($table, $dbCheckTables) !== FALSE ) {
                $count++;
            }
        }
        if ( ($count == count($dbCheckTables)) || ($count == 0) ) {
            userMessage("Database Migration Pending");
            dbDoMigration($db);

            return TRUE;
        } else {
            return FALSE;
        }
    }
        
    function dbEmpty($db)
    {
        $_SESSION['db_version']['skip_schema'] = FALSE;
        $tables = dbListRelevantTables($db);
        if ( $tables === FALSE ) {
            userMessage("error", "Problem scanning database - " . mysqli_error($db) );
            return FALSE;
        }
        if ( count($tables) == 0 ) {
            return TRUE;
        } else {
            if ( dbComplete($tables) ) {
                userMessage("warn", "Database already populated");
                $_SESSION['db_version']['skip_schema'] = TRUE;
                return TRUE;
            } else {
                userMessage("error", "Database contains non-simian tables");
                return FALSE;
            }
        }
    }

    function dbDoMigration($db) {
        if ( ! dbSelect($db) ) {
            return FALSE;
        }

	$mig_query = 'SELECT MAX(version) FROM `migrations`';
        $result = mysqli_query($db, $mig_query);
        if ( mysqli_errno($db) != 0 ) {
	    $mserr = mysqli_error($db);
	    if(strpos($mserr,"Table") && strpos($mserr,"doesn't exist")) {
		$todo = 0;
	    } else {
                userMessage("error", "Problem checking migration version - " . $mserr) );
		return FALSE;
	    }
        }
	if ($result === FALSE) {
	    $todo = 0;
	} else {

	    $row = mysql_fetch_array($result, MYSQL_NUM);
    	    $todo = $row[0] + 1;  
	}

	dbMigrate($db, $todo,configGetDBValue('db_name') );
    }

    function dbMigrate($db, $todo, $store) {
	$migrations = array();

	$dir = "../Installer/migrations/"; 

	if($handle = opendir($dir)) { 
    	    while($file = readdir($handle)) { 
	        clearstatcache(); 
        	if(is_file($dir.'/'.$file)) {
		    $file_version = substr($file,0,strpos($file,'-')-1);
		    if (($file_version >= $todo) && (strpos($file,$store))) {
		        # omfg execute the sql already :p
		        dbQueriesFromFile($db,$dir . $file);
                        userMessage("warn","Migration: " . $file_version);
		    }
		}

            }
            closedir($handle);
        }
    }

    function dbFlush($db) {
        $done = FALSE;
        while ( ! $done ) {
            $result = mysqli_store_result($db);
            if ( mysqli_more_results($db) ) {
                if ( mysqli_errno($db) != 0 ) {
                    userMessage("warn", "DB Problem - " . mysqli_error($db) );
                    userMessage("warn", var_dump(debug_backtrace()));
                }
                mysqli_next_result($db);
                if ( mysqli_errno($db) != 0 ) {
                    userMessage("warn", "DB Problem - " . mysqli_error($db) );
                    userMessage("warn", var_dump(debug_backtrace()));
                }
            } else {
                $done = TRUE;
            }
        }
    }

    function dbQueriesFromFile($db, $file)
    {
        $contents = file($file);
        $current_query = '';
        foreach ( $contents as $line_num => $line ) {
            if (substr($line, 0, 2) != '--' && $line != '') {
                $current_query .= $line;
                if (substr(trim($line), -1, 1) == ';') {
                    $result = mysqli_query($db, $current_query);
                    if ( $result === FALSE || mysqli_errno($db) != 0 ) {
                        userMessage("error", "Problem loading schema $schema - " . mysqli_error($db) );
                        return FALSE;
                    }
                    dbFlush($db);
                    $current_query = '';
                }
            }
        }
        
    }

    function dbWrite()
    {
        if ( $_SESSION['db_version']['skip_schema'] === TRUE ) {
            userMessage("warn", "Skipped loading of schema and fixtures");
            return TRUE;
        }
        global $dbSchemas, $dbFixtures;
        $db = dbHandle();
        if ( ! dbSelect($db) ) {
            return FALSE;
        }
        # foreach ( $dbSchemas as $schema ) {
        #    dbQueriesFromFile($db, $schema);
        # }
        
	dbDoMigration($db);

        foreach ( $dbFixtures as $fixture ) {
            $result = mysqli_multi_query($db, file_get_contents($fixture) );
            if ( $result === FALSE || mysqli_errno($db) != 0 ) {
                userMessage("error", "Problem loading fixture $fixture - " . mysqli_error($db) );
                return FALSE;
            }
            dbFlush($db);
        }
        mysqli_close($db);
        return TRUE;
    }

?>
