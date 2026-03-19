#!/usr/bin/env python3

import json
import subprocess
import argparse

def get_gcp_instances():
    """Get GCP instances using gcloud command"""
    try:
        #project IDs
        projects = [
            'dev-env-project-490714',
            'stg-env-project', 
            'prod-env-project-490714'
        ]
        all_instances = []
        
        for project in projects:
            cmd = [
                'gcloud', 'compute', 'instances', 'list',
                '--project', project,
                '--format=json(name,networkInterfaces,labels,tags)'
            ]
            result = subprocess.run(cmd, capture_output=True, text=True)
            instances = json.loads(result.stdout)
            
            # Add project info to each instance
            for instance in instances:
                instance['project'] = project
            all_instances.extend(instances)
        
        inventory = {
            '_meta': {
                'hostvars': {}
            },
            'all': {
                'children': ['dev', 'staging', 'prod']
            }
        }
        
        # Group instances by environment label
        for instance in all_instances:
            env = instance.get('labels', {}).get('environment', 'unknown')
            name = instance['name']
            
            if env not in inventory:
                inventory[env] = {'hosts': []}
            
            # Get internal IP
            internal_ip = instance['networkInterfaces'][0]['networkIP']
            
            # Get external IP if exists
            external_ip = None
            if 'accessConfigs' in instance['networkInterfaces'][0]:
                external_ip = instance['networkInterfaces'][0]['accessConfigs'][0]['natIP']
            
            inventory[env]['hosts'].append(name)
            
            # Add hostvars
            inventory['_meta']['hostvars'][name] = {
                'ansible_host': external_ip or internal_ip,
                'internal_ip': internal_ip,
                'environment': env,
                'project': instance['project'],
                'zone': instance.get('zone', '').split('/')[-1]
            }
        
        return inventory
        
    except Exception as e:
        print(json.dumps({'_meta': {'hostvars': {}}}))
        return {'_meta': {'hostvars': {}}}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--host', action='store')
    args = parser.parse_args()
    
    inventory = get_gcp_instances()
    
    if args.host:
        print(json.dumps(inventory['_meta']['hostvars'].get(args.host, {})))
    else:
        print(json.dumps(inventory))