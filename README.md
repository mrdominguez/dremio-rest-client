# dremio-rest-client
Dremio REST API client

### Table of Contents
[Release Notes](https://github.com/mrdominguez/dremio-rest-client/blob/master/README.md#release-notes)  
[Synopsis](https://github.com/mrdominguez/dremio-rest-client/blob/master/README.md#synopsis)  
[Installation](https://github.com/mrdominguez/dremio-rest-client/blob/master/README.md#installation)  
[Setting Credentials](https://github.com/mrdominguez/dremio-rest-client/blob/master/README.md#setting-credentials)  
[Usage](https://github.com/mrdominguez/dremio-rest-client/blob/master/README.md#usage)  
[Sample Output](https://github.com/mrdominguez/dremio-rest-client/blob/master/README.md#sample-output)

## Release Notes
### Version 1.1 is now available!
- Added support for redirections

Follow redirects is enabled by default. To disable, use `-noredirect`.

### Version 1.0
- Initial release of my Dremio REST client: `dremio-rest.pl`
- All arguments are flag-based (see [Usage](https://github.com/mrdominguez/dremio-rest-client/blob/master/README.md#usage))
- Improved readability of the JSON response content output by using **Data::Dumper**
- Use `-login` to get a token from Dremio and save it to a file (implies `-t=default_token_file`)
- Set `-t` to pass a token string or the path to a token file (default: `$HOME/.dremio_token`)

## Synopsis
AUTHOR: Mariano Dominguez  
<marianodominguez@hotmail.com>  
https://www.linkedin.com/in/marianodominguez

FEEDBACK/BUGS: Please contact me by email.

The Dremio REST client is a Perl script to interact with [Dremio](https://www.dremio.com/) via [REST API](https://docs.dremio.com/rest-api/)

## Installation
This utility is written in *Perl* and have been tested using version *5.1x.x* on *RHEL 6/7*, as well as *macOS Sierra (10.12)* and after.

Use [cpan](http://perldoc.perl.org/cpan.html) to install the following modules; alternately, download them from the [CPAN Search Site](http://search.cpan.org/) for manual installation:
- **REST::Client**
- **JSON**
- **IO::Prompter** (for username/password prompt)

Additionally, **LWP::Protocol::https** is required for HTTPS support.

The following is an example of an unattended installation script for RHEL-based distributions:
```
#!/bin/bash

sudo yum -y install git cpan gcc openssl openssl-devel

REPOSITORY=dremio-rest-client
cd; git clone https://github.com/mrdominguez/$REPOSITORY

cd $REPOSITORY
chmod +x *.pl
ln -s dremio-rest.pl dremio-rest

cd; grep "PATH=.*$REPOSITORY" .bashrc || echo -e "\nexport PATH=\"\$HOME/$REPOSITORY:\$PATH\"" >> .bashrc

echo | cpan
. .bashrc

perl -MCPAN -e 'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit'
cpan CPAN::Meta::Requirements CPAN
cpan Module::Metadata JSON REST::Client IO::Prompter

dremio-rest -help
echo "Run 'source ~/.bashrc' to refresh environment variables"
```

## Setting Credentials
Dremio credentials can be passed by using the `-u` (username) and `-p` (password) options. The `-p` option can be set to the password string itself (**not recommended**) or to a file containing the password:

`$ dremio-rest.pl -u=username -p=/path/to/password_file -host=dremio_host`

Both username and password values are optional. If no value is provided, there will be a prompt for one.

Credentials can also be passed by using the `$DREMIO_REST_USER` and `$DREMIO_REST_PASS` environment variables. Just like the `-p` option, the `$DREMIO_REST_PASS` environment variable can be set to a file containing the password:
```
export DREMIO_REST_USER=username
export DREMIO_REST_PASS=/path/to/password_file
```

The aforementioned environment variables can be loaded through a credentials file (`$HOME/.dremio_rest`), if it exists:
```
$ cat $HOME/.dremio_rest
DREMIO_REST_USER:username
DREMIO_REST_PASS:/path/to/password_file
```

NOTE: Quote passwords containing white spaces and, instead of using the credentials file, set the `-p` option or `export DREMIO_REST_PASS`.

The preference is as follows (highest first):

1. Options `-u`, `-p`
2. Credentials file
3. Environment variables (using the `export` command)

## Usage
```
dremio-rest.pl [-help] [-version] [-d] [-u[=username]] [-p[=password]] [-https] [-host=hostname[:port]]
	[-noredirect] [-m=method] [-b=body_content] [-f=json_file] [-t] [-json] -login | -r=rest_resource

	 -help : Display usage
	 -version : Display version information
	 -d : Enable debug mode
	 -u : Dremio username (environment variable: $DREMIO_REST_USER | default: $USER -current user-)
	 -p : Dremio password or path to password file (environment variable: $DREMIO_REST_PASS | default: undef)
		  Credentials file: $HOME/.dremio_rest (set env variables using colon-separated key/value pairs)
	 -https : Use HTTPS to communicate with Dremio (default: HTTP)
	 -host : Dremio hostname:port (default: localhost:9047)
	 -noredirect : Do not follow redirects
	 -m : Method | GET, POST, PUT, DELETE (default: GET)
	 -b : Body content (JSON format)
	 -f : JSON file containing body content
	 -t : Token string or path to token file (default: $HOME/.dremio_token)
	 -json : Do not use Data::Dumper to output the response content (default: disabled)
	 -login : Get token from Dremio and save to file (implies -t=default_token_file)
	 -r : REST resource|endpoint (example: /api/v3/catalog)
```

## Sample Output
Get token using .dremio_rest credentials
```
$ cat .dremio_rest
DREMIO_REST_USER:admin
DREMIO_REST_PASS:dremio123
$
$ dremio-rest -login -https
$VAR1 = {
          'admin' => 'true',
          'firstName' => 'Admin',
          'permissions' => {
                             'canChatForSupport' => 'false',
                             'canEmailForSupport' => 'true',
                             'canUploadProfiles' => 'true',
                             'canDownloadProfiles' => 'true'
                           },
          'showUserAndUserProperties' => 'false',
          'userCreatedAt' => 0,
          'version' => '11.0.0-202011171636110752-16ab953d',
          'userId' => 'admin',
          'clusterCreatedAt' => '1605517486712',
          'userName' => 'admin',
          'token' => '1laebft698qloac3tnd2aka4eg',
          'clusterId' => '8b184c48-1a29-42a4-a0b6-8cabc6393496',
          'expires' => '1612327001881'
        };
Saving token to file /root/.dremio_token
```

Get token passing credentials via command line
```
$ dremio-rest -login -https -u=mdom -p -t=mdom.token -json
Password: *****
{"token":"gb3poqo35rr7akeodrah9lnpdu","userName":"mdom","firstName":"Mariano","expires":1612327143878,"userId":"mdom","admin":false,"clusterId":"8b184c48-1a29-42a4-a0b6-8cabc6393496","clusterCreatedAt":1605517486712,"showUserAndUserProperties":false,"version":"11.0.0-202011171636110752-16ab953d","permissions":{"canUploadProfiles":true,"canDownloadProfiles":true,"canEmailForSupport":true,"canChatForSupport":false},"userCreatedAt":0}
Saving token to file mdom.token
```

List top-level catalog containers
```
$ # Using non-default token file
$ dremio-rest -https -t=mdom.token -r=/api/v3/catalog
$VAR1 = {
          'data' => [
                      {
                        'createdAt' => '2020-11-19T14:56:23.886Z',
                        'containerType' => 'HOME',
                        'type' => 'CONTAINER',
                        'tag' => 'ua7yF9AuhYM=',
                        'path' => [
                                    '@mdom'
                                  ],
                        'id' => '66d013d7-f021-46a8-89c4-6874972741b9'
                      },
                      {
                        'createdAt' => '2021-01-27T16:08:03.153Z',
                        'containerType' => 'SOURCE',
                        'type' => 'CONTAINER',
                        'tag' => 'Pz4Ov284YhU=',
                        'path' => [
                                    'Samples'
                                  ],
                        'id' => '6bd12a4f-828a-4056-b825-95002bc40a14'
                      }
                    ]
        };
```

Retrieve information about a specific catalog entity using its path
```
$ # Using default token file .dremio_token
$ dremio-rest -https -r=/api/v3/catalog/by-path/Samples/samples.dremio.com
$VAR1 = {
          'permissions' => [],
          'entityType' => 'folder',
          'accessControlList' => {},
          'children' => [
                          {
                            'type' => 'FILE',
                            'path' => [
                                        'Samples',
                                        'samples.dremio.com',
                                        '"SF weather 2018-2019.csv"'
                                      ],
                            'id' => 'dremio:/Samples/samples.dremio.com/"SF weather 2018-2019.csv"'
                          },
                          {
                            'type' => 'FILE',
                            'path' => [
                                        'Samples',
                                        'samples.dremio.com',
                                        '"SF_incidents2016.json"'
                                      ],
                            'id' => 'dremio:/Samples/samples.dremio.com/"SF_incidents2016.json"'
                          },
                          {
                            'type' => 'FILE',
                            'path' => [
                                        'Samples',
                                        'samples.dremio.com',
                                        '"zip_lookup.csv"'
                                      ],
                            'id' => 'dremio:/Samples/samples.dremio.com/"zip_lookup.csv"'
                          },
                          {
                            'datasetType' => 'PROMOTED',
                            'type' => 'DATASET',
                            'path' => [
                                        'Samples',
                                        'samples.dremio.com',
                                        '"zips.json"'
                                      ],
                            'id' => '6156d873-8567-4883-a916-2e5fd1d30a35'
                          },
                          {
                            'containerType' => 'FOLDER',
                            'type' => 'CONTAINER',
                            'path' => [
                                        'Samples',
                                        'samples.dremio.com',
                                        '"Dremio University"'
                                      ],
                            'id' => 'dremio:/Samples/samples.dremio.com/"Dremio University"'
                          },
                          {
                            'containerType' => 'FOLDER',
                            'type' => 'CONTAINER',
                            'path' => [
                                        'Samples',
                                        'samples.dremio.com',
                                        '"NYC-taxi-trips"'
                                      ],
                            'id' => 'dremio:/Samples/samples.dremio.com/"NYC-taxi-trips"'
                          }
                        ],
          'tag' => 'tUGO02kqiu0=',
          'path' => [
                      'Samples',
                      'samples.dremio.com'
                    ],
          'id' => 'fd73f353-c449-475f-8e04-a67b27da56c1'
        };
```

Query table and get results
```
$ dremio-rest -r=/api/v3/sql -m=post \
-b='{"sql":"select * from \"zips.json\" limit 1","context":["Samples","samples.dremio.com"]}'
$VAR1 = {
          'id' => '1fbefc28-dec1-9cbc-4f24-972d21e68500'
        };
$ dremio-rest -r=/api/v3/job/1fbefc28-dec1-9cbc-4f24-972d21e68500
$VAR1 = {
          'queueName' => 'Low Cost User Queries',
          'startedAt' => '2021-03-04T15:59:18.480Z',
          'cancellationReason' => '',
          'resourceSchedulingStartedAt' => '2021-03-04T15:59:18.501Z',
          'rowCount' => 1,
          'errorMessage' => '',
          'resourceSchedulingEndedAt' => '2021-03-04T15:59:18.547Z',
          'queueId' => 'ca9161e4-e470-4fe2-b03b-930b20c5e72e',
          'jobState' => 'COMPLETED',
          'queryType' => 'REST',
          'endedAt' => '2021-03-04T15:59:19.359Z'
        };
$ dremio-rest -r=/api/v3/job/1fbefc28-dec1-9cbc-4f24-972d21e68500/results
$VAR1 = {
          'rowCount' => 1,
          'rows' => [
                      {
                        'city' => 'AGAWAM',
                        '_id' => '01001',
                        'loc' => [
                                   '-72.622739',
                                   '42.070206'
                                 ],
                        'pop' => 15338,
                        'state' => 'MA'
                      }
                    ],
          'schema' => [
                        {
                          'name' => 'city',
                          'type' => {
                                      'name' => 'VARCHAR'
                                    }
                        },
                        {
                          'name' => 'loc',
                          'type' => {
                                      'subSchema' => [
                                                       {
                                                         'type' => {
                                                                     'name' => 'DOUBLE'
                                                                   }
                                                       }
                                                     ],
                                      'name' => 'LIST'
                                    }
                        },
                        {
                          'name' => 'pop',
                          'type' => {
                                      'name' => 'BIGINT'
                                    }
                        },
                        {
                          'name' => 'state',
                          'type' => {
                                      'name' => 'VARCHAR'
                                    }
                        },
                        {
                          'name' => '_id',
                          'type' => {
                                      'name' => 'VARCHAR'
                                    }
                        }
                      ]
        };
```

Create, list and delete Personal Access Token (PAT)
```
$ dremio-rest -https -m=post \
-b='{"label":"token2","millisecondsToExpire":"86400000"}' -r=/api/v3/user/admin/token
nSOLFDEpQx2xTJxyS/xN7Gin/ZYzPM/bG7JQ5EES7v5RvFa1iTKmqC4+VAQ5+w==
$ dremio-rest -https -r=/api/v3/user/mdom/token
$VAR1 = {
          'data' => [
                      {
                        'createdAt' => '2021-02-01T14:52:22.877Z',
                        'uid' => 'admin',
                        'label' => 'token1',
                        'expiresAt' => '2021-02-02T14:52:22.877Z',
                        'tid' => '19499841-21d3-44cd-98f3-55e3cad10df8'
                      },
                      {
                        'createdAt' => '2021-02-01T23:03:05.199Z',
                        'uid' => 'admin',
                        'label' => 'token2',
                        'expiresAt' => '2021-02-02T23:03:05.199Z',
                        'tid' => '9d238b14-3129-431d-b14c-9c724bfc4dec'
                      }
                    ]
        };
$ dremio-rest -https -m=delete \
-r=/api/v3/user/admin/token/19499841-21d3-44cd-98f3-55e3cad10df8
$ dremio-rest -https -r=/api/v3/user/mdom/token
$VAR1 = {
          'data' => [
                      {
                        'createdAt' => '2021-02-01T23:03:05.199Z',
                        'uid' => 'admin',
                        'label' => 'token2',
                        'expiresAt' => '2021-02-02T23:03:05.199Z',
                        'tid' => '9d238b14-3129-431d-b14c-9c724bfc4dec'
                      }
                    ]
        };
```
