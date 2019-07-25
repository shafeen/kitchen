# kitchen
*Too many cooks!*

AWS OpsWorks cookbooks I've written to get some SERIOUS work done. 

## Scenario Index
> All scenarios are OpsWorks and ubuntu specifc. We'll follow the convention that "layers" 
will have the same shortnames as the "apps" deployed onto their instances.

For info on specific environment variables needed on the app deployed, go read the 
actual recipes. And remember, the **execution order of the recipes** matter, so 
don't modify the orders willy nilly.

### Simple nodejs deploy with pm2
- setup: `opstest::node10`, `opstest::npm_globals`
- deploy: `opstest::pm2deploy`

### Simple nodejs deploy with pm2 + localhost reverse-proxy
- setup: `opstest::nginx`, `opstest::node10`, `opstest::npm_globals`
- deploy: `opstest::pm2deploy`, `opstest::nginx_localhost_reverseproxy`

### Add simple application/error log rotation
You just add the `opstest::deploy_logrotate_simple` to your list
of deploy recipes.
- setup: \[any setup recipe you need\]
- deploy: \[relevant deploy recipe\], `opstest::deploy_logrotate_simple`

### Run a metrics server with prometheus + grafana
Note that you need a separate metrics "app" to house the environment variables containing
settings for the prometheus servers (like what DNS servers to scrape).
- setup: `opstest::nginx`, `opstest::node10`, `opstest::npm_globals`, 
  `opstest::prometheus_grafana`
- deploy: `opstest::prometheus_dns_deploy`, `opstest::nginx_localhost_reverseproxy`

### Instances self updating their dns entries upon deployment
You just add the `opstest::update_internal_dns` to your deploy recipe list 
and ensure that you have `opstest::node10` in your setup recipe list (along
with your other needed setup recipes).
- setup: `opstest::node10`, \[any setup recipe you need\]
- deploy: \[relevant deploy recipe\], `opstest::update_internal_dns`

### Simple round-robin Load balancer 
Coming soon!
