Experiment to build Windows services with nim

!this is not a full featured service!

pull request welcome!

This repo contains code to create and manage windows services.
Executables that implements windows services has to tell the 
operating system (the Service Control Manager https://docs.microsoft.com/en-us/windows/desktop/services/service-control-manager) 
which procedures to run when the service starts, this means one executable could implement
multiple services (by the time of writing this, multiple services are not supported yet)

steps to install a service:

1. use proc from winServiceControl.nim to register services to the SCM
2. build your service, then wrap your service entry point with `wrapServiceMain`
3. (atm this is still necessary) build the service dispatch table by hand: 
```nim
    var dispatchTable = [
        SERVICE_TABLE_ENTRY(lpServiceName: SERVICE_NAME, lpServiceProc: wrapServiceMain(serviceMain)),
        SERVICE_TABLE_ENTRY(lpServiceName: nil, lpServiceProc: nil) # last entry must be nil
    ]

    echo StartServiceCtrlDispatcher( (addr dispatchTable[0]).LPSERVICE_TABLE_ENTRY)
```
4. now the service should be registered in the SCM and you should be able to start and stop the service
   from the windows service control panel / net start / sc start
5. Your application should determine if the service must stop, to do this check the value of
   `gSvcStatus.dwCurrentState != SERVICE_RUNNING` if this is not `SERVICE_RUNNING` then return out of   your applications main loop 

Example:

Service control (could be implementet in the service but also could be standalone)
depending on your windows settings this might require administrator privileges!:

````nim
import winServiceControl
var scm = openServiceManager()
discard scm.createService("service_name", "service_display_name", "/path/to/service.exe")
discard scm.startService("service_name")
```

The service:
```nim
import winservice
import times, os
proc serviceMain(gSvcStatus: SERVICE_STATUS) =
    ## a service main
    ## use gScvStatus to check if we should stop periodically!
    var fh = open("C:/servicelog.txt", fmAppend)
    fh.write("SERVICE STARTED\n")
    fh.flushFile()
    while gSvcStatus.dwCurrentState == SERVICE_RUNNING: # when we should stop this evaluates to false
        reportSvcStatus(SERVICE_RUNNING, NO_ERROR, 0) # we periodically tell the SCM that we're running
        fh.write($epochTime() & "\n")
        fh.flushFile()
        sleep(1_000)   
    fh.write("SERVICE CLOSED BY MANAGER!\n")
    fh.flushFile()

var wrapped = wrapServiceMain(serviceMain) # wrap your main procedure
var dispatchTable = [
    SERVICE_TABLE_ENTRY(lpServiceName: SERVICE_NAME, lpServiceProc: wrapped),
    SERVICE_TABLE_ENTRY(lpServiceName: nil, lpServiceProc: nil) # last entry must be nil
]

echo StartServiceCtrlDispatcher( (addr dispatchTable[0]).LPSERVICE_TABLE_ENTRY)
```  

