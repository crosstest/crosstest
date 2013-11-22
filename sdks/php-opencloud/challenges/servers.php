<?php
require('vendor/autoload.php');
use OpenCloud\Rackspace;

$endpoint = getenv('RAX_AUTH_URL') . '/v2.0/';
$credentials = array(
    'username' => getenv('RAX_USERNAME'),
    'apiKey' => getenv('RAX_API_KEY')
);

$rackspace = new Rackspace($endpoint, $credentials);

$compute = $rackspace->computeService('cloudServersOpenStack', getenv('RAX_REGION'));

$server = $compute->Server();
$server->name = 'MyNewServer';
$flavor_id = intval(getenv('SERVER1_FLAVOR'));

$server->image = $compute->Image(getenv('SERVER1_IMAGE'));
$server->flavor = $compute->Flavor($flavor_id);

// create it
print("Creating server...");
$server->Create();
print("requested, now waiting...\n");
print("ID=".$server->id."...\n");
$server->WaitFor("ACTIVE", 600, 'dot');
print("done\n");
exit(0);

function dot($server) {
  printf("%s %3d%%\n", $server->status, $server->progress);
}

?>
