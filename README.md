# appd-config-transfer
Bash script to transfer configurations between Controllers. You can export and import Actions, Health Rules, and Policies.

# Installation

## Important
The configurations get transferred based on the Application name. This Application must exist in *both* Controllers. It's best to have the agents reporting to the destination Controller, but it might be possible to create the Application manually in the Controller UI without having the agents reporting first. However, certain Health Rules might fail to upload if they rely on BTs that have not yet been registered.

### Permissions
```
chmod u+x config-transfer.sh
```

### Update credentials.sh
This file stores all of your Controller access credentials. Update the various fields as appropriate for your Controllers. FYI, many on premises Controllers simply have 'customer1' as the account name.

```
SOURCE_URL="http://source.example.com:8090"
SOURCE_USERNAME="user1"
SOURCE_PASSWORD="password1"
SOURCE_ACCOUNT="customer1"

DESTINATION_URL="https://destination.example.com:8181"
DESTINATION_USERNAME="user2"
DESTINATION_PASSWORD="password2"
DESTINATION_ACCOUNT="acme-prod"
```

# Usage
`./config-transfer.sh --application=APP_NAME|all --config=actions|healthrules|policies|all --action=export|import|both`

`--application`
Pass in a single application name or pass in the word "all" to act on every application in the source controller.
   
`--config`
What kind of configuration do you want to transfer? You can choose individual config types or just grab them all.

`--action`
Do you want to export, import or do both? Specify your action via this parameter. Most users will want the 'both' option, but this requires network connectivity to both Controllers at once. Use the 2-part export/import functions otherwise.

# Examples
### Transfer All Configs for All Apps
```
./config-transfer.sh --application=all --config=all --action=both
```

### Export and then Import Actions for All Apps
```
./config-transfer.sh --application=all --config=actions --action=export
./config-transfer.sh --application=all --config=actions --action=import
```

### Export and then Import Health Rules for a Single App
```
./config-transfer.sh --application=MyApp --config=healthrules --action=export
./config-transfer.sh --application=MyApp --config=healthrules --action=import
```

### Export and then Import Policies for a Single App
```
./config-transfer.sh --application=MyApp --config=policies --action=export
./config-transfer.sh --application=MyApp --config=policies --action=import
```
