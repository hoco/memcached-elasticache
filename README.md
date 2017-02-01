Memcached ElastiCache [![Build Status](https://travis-ci.org/hoco/memcached-elasticache.svg?branch=master)](https://travis-ci.org/hoco/memcached-elasticache)
=================

Use [AWS ElastiCache AutoDiscovery](http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.html) to automatically configure your [memcached](https://github.com/arthurnn/memcached) client with all the nodes in your cluster.  
Forked from [ktheory/dalli-elasticache](https://github.com/ktheory/dalli-elasticache).


Installation
-------

Install the rubygem:

```
# in your Gemfile
gem 'memcached', git: 'https://github.com/arthurnn/memcached'
gem 'memcached-elasticache'
```

Usage
-------
```
config_endpoint = 'sample.vfdnac.cfg.use1.cache.amazonaws.com:11211'

options = {
  # options for Memcached::Elasticache::Client
  refresh_interval: 60,
  max_retry_count: 1,
  # options for Memcached::Client
  ttl: 0,
  prefix: 'dummy'
}

client = Memcached::Elasticache::Client.new(config_endpoint, options) 
client.set 'sam', 'ple'
=> true
```


License
-------

Original work Copyright 2013 Aaron Suggs  
Modified work Copyright 2017 Shogo Asahara

Released under an [MIT License](http://opensource.org/licenses/MIT)
