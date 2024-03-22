//
//			 	           Unclassified
//
///////////////////////////////////////////////////////////////////////////////
//////////////////////// AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 //////
//
// Purpose: Script processor used by Metricbeat to combine metrics from multiple
//          metricsets and determine status of Applications made up of multiple
//          processes and/or services. Summary results are created each time
//          a process_summary event is seen by the script.  The results are
//          added to the process_summary document and sent to Logstash.
//
// Tracking#: TBD
//
// File name: appmonitor_win.js
//
// Location: /etc/metricbeat
//
// Version: v1.00
//
// Revisions:
//   version, RFC, Author’s name, date (yyyy-mm-dd): comments
//   v1.00, TBD, Steve Truxal, 2021-05-11: Initial Version
//
// Site/System: All Linux Machines controlled by Puppet
//
// Deficiency: N/A
//
// Use: Script processor is used by Metricbeat
//
// Users: Script is not for use by users
//
// DAC Setting: 644 root root
//
// Frequency: Script is used by Metricbeat continually while it is running
//
// Information Security Authorization
// ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
//
// Lead System Engineering Authorization
// AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
//
///////////////////////////////////////////////////////////////////////////////
//

var params = {}
function register(scriptParams) {
  params = scriptParams

  // On windows case is insenstive and we have seen issues with services or processes
  // having different case on different hosts for this reason all services and
  // process names in yml configuration will be lower cased.
  var app, processes, services, service, process
  for (app in params.apps) {
    processes = params.apps[app]['processes']
    services = params.apps[app]['services']
    for (service in services) {
      var tmpsvc = JSON.parse(JSON.stringify(services[service]))
      delete services[service]
      services[service.toLowerCase()] = JSON.parse(JSON.stringify(tmpsvc))
    }
    for (process in processes) {
      var tmpprc = JSON.parse(JSON.stringify(processes[process]))
      delete processes[process]
      processes[process.toLowerCase()] = JSON.parse(JSON.stringify(tmpprc))
    }
  }
}
function process(event) {
  var processes
  var services

  var metricset = event.Get('metricset.name')

  switch (metricset) {
    case 'cpu':
      params.metrics['cpu']['curval'] = event.Get('system.cpu.total.norm.pct')
      break
    case 'memory':
      //metrics['memory']['curval'] = event.Get("system.memory.used.pct")
      params.metrics['memory']['curval'] = event.Get(
        'system.memory.actual.used.pct'
      )
      break
    case 'network':
      var inbytes = event.Get('host.network.in.bytes')
      if (inbytes != null) {
        params.network['curBytesin'] = inbytes
        params.network['curBytesout'] = event.Get('host.network.out.bytes')
      }
      break
    case 'filesystem':
      var fval = event.Get('system.filesystem.used.pct')
      if (fval > params.metrics['filesystem']['curval']) {
        params.metrics['filesystem']['curval'] = fval
        params.metrics['filesystem']['mount_point'] = event.Get(
          'system.filesystem.mount_point'
        )
      }
      break
    case 'process':
      var candrop = true
      var app
      var pname = event.Get('process.name')
      if (pname) {
        // Split upto first perod for windows processes
        // this will remove the .exe if it exists
        pname = pname.split('.')[0].toLowerCase()

        for (app in params.apps) {
          processes = params.apps[app]['processes']
          if (processes != null && pname in processes) {
            processes[pname].running = true
            candrop = false
          }
        }

        if (candrop == true) {
          var path = event.Get('system.process.cmdline')
          path = path.toLowerCase()
          if (path.indexOf('system32') !== -1) {
            event.Cancel()
          }
        }
      }
      break
    case 'service':
      var candrop = true
      // Note this field is different for linux
      var sname = event.Get('windows.service.name')
      if (sname) {
        sname = sname.split('.')[0].toLowerCase()

        for (app in params.apps) {
          services = params.apps[app]['services']
          if (services != null && sname in services) {
            // Note this field is different for linux
            var state = event.Get('windows.service.state')
            if (state.toLowerCase() == 'running') {
              services[sname].running = true
            }
            candrop = false
          }
        }

        if (candrop == true) {
          var path = event.Get('windows.service.path_name')
          path = path.toLowerCase()
          if (path.indexOf('system32') !== -1) {
            event.Cancel()
          }
        }
      }
      break
    case 'process_summary':
      event.Put('Debug-Metrics', params.metrics)
      if (params.not_justStarted) {
        var issues
        var appstatus
        var proc
        var report = []
        var hosthealth = 'OK'
        var symptoms = []
        for (app in params.apps) {
          issues = { processes: [], services: [] }
          processes = params.apps[app]['processes']
          services = params.apps[app]['services']
          appstatus = 'OK'
          for (proc in processes) {
            if (processes[proc].running != true) {
              if (appstatus.toLowerCase() != 'down') {
                appstatus = processes[proc].effect
              }
              issues['processes'].push(proc)
            }
            processes[proc].running = false
          }

          for (sname in services) {
            if (services[sname].running != true) {
              if (appstatus.toLowerCase() != 'down') {
                appstatus = services[sname].effect
              }
              issues['services'].push(sname)
            }
            services[sname].running = false
          }

          if (issues['processes'].length == 0) issues['processes'].push('none')

          if (issues['services'].length == 0) issues['services'].push('none')

          if (appstatus != 'OK') {
            symptoms.push(app + ':' + appstatus)
            if (hosthealth.toLowerCase() != 'down') {
              var maxEffect = params.apps[app]['hosteffect']
              if (
                maxEffect.toLowerCase() == 'down' &&
                appstatus.toLowerCase() == 'down'
              ) {
                hosthealth = 'Down'
              } else {
                hosthealth = 'Degraded'
              }
            }
          }

          report.push({
            Name: app,
            Status: appstatus,
            'Issues.processes': issues['processes'],
            'Issues.services': issues['services'],
          })
        }
        event.Put('APPS', report)

        // Make local copy of fields for Document
        var max_used = params.metrics['filesystem']['curval']
        var mount_point = params.metrics['filesystem']['mount_point']
        var cpu = params.metrics['cpu']['curval']
        var mem = params.metrics['memory']['curval']
        var inbytes = params.network['curBytesin']
        var outbytes = params.network['curBytesout']
        var cpu_thd = params.metrics['cpu']['threshold']
        var mem_thd = params.metrics['memory']['threshold']
        var fs_thd = params.metrics['filesystem']['threshold']

        event.Put('Metrics.cpu', cpu)
        event.Put('Metrics.cpu_threshold', cpu_thd)
        event.Put('Metrics.memory', mem)
        event.Put('Metrics.memory_threshold', mem_thd)
        event.Put('Metrics.filesystem.max_used', max_used)
        event.Put('Metrics.filesystem.mount_point', mount_point)
        event.Put('Metrics.filesystem.threshold', fs_thd)
        event.Put('Metrics.network.in.bytes', inbytes)
        event.Put('Metrics.network.out.bytes', outbytes)

        // Check to see if any thresholds have been breached
        var tmphealth = 'OK'
        var metric
        for (metric in params.metrics) {
          if (
            params.metrics[metric]['curval'] >
            params.metrics[metric]['threshold']
          ) {
            symptoms.push(metric)
            tmphealth = 'Degraded'
          }
        }

        // Only use threshold host health if all Apps are OK
        if (hosthealth == 'OK') {
          hosthealth = tmphealth
        }
        // If there are no symptoms then lets show 'none'
        if (symptoms.length == 0) {
          symptoms.push('none')
        }
        event.Put('host.Health', hosthealth)
        event.Put('host.HealthSymptoms', symptoms)

        // Clear global filesystem information in case it goes down
        params.metrics['filesystem']['curval'] = 0
        params.metrics['filesystem']['mount_point'] = 'none'
      } else {
        params.not_justStarted = true
        event.Cancel()
      }
      break
  }
}
//			 	           Unclassified
