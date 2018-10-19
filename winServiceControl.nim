#
#
#               nimWindowsService
#        (c) Copyright 2018 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## register, delete and control windows services.
# loosely based on: https://docs.microsoft.com/de-de/windows/desktop/Services/svc-cpp

import oldwinapi/windows
import os

proc close*(service: SC_HANDLE): bool = return service.CloseServiceHandle().bool

proc openServiceManager*(accessRights: DWORD = SC_MANAGER_ALL_ACCESS): SC_HANDLE = 
    ## opens a handle to the ServiceControlManager.
    ## raises exception if this failes.
    ## (might require administrator access!)
    var scmManager: SC_HANDLE = OpenSCManager(
        nil, # local computer
        nil, # serviceactive database ?
        accessRights # full access rights
    )
    if scmManager == 0:
        raise newException(OsError,  "could not get a handle to Service Control Manager (SCManager): " & $GetLastError())
    return scmManager

proc getServiceByName*(scmManager: SC_HANDLE, serviceName: string): SC_HANDLE =
    ## returns a handle to the service
    ## trows os error if failed
    ## handle to service must be closed manually by `CloseServiceHandle(service)`
    result = scmManager.OpenService(serviceName.LPCSTR, SERVICE_ALL_ACCESS)
    if result == 0:
        raise newException(OsError, "could not open service: " & serviceName & " errorCode: " &  $GetLastError() )

proc deleteService*(scmManager: SC_HANDLE, serviceName: string): bool = 
    ## deletes a windows service by its ServiceName (*not* display name!)
    var service: SC_HANDLE 
    try:
        service = scmManager.getServiceByName(serviceName)
    except:
        echo "could not open service vor deletion"
        return false
    result = service.DeleteService().bool
    discard service.close()

proc createService*(scmManager: SC_HANDLE, serviceName, serviceDisplayName, path: string, 
        startType: DWORD = SERVICE_AUTO_START): bool =
    ## registers a service in the scmManager
    ##  serviceName: is the internal service name (sc query serviceName)
    ##  serviceDisplayName: is the visible service name (net start serviceDisplayName)
    ##  path: is the absolute path to the service executable, (*not* neccessary this control application, see winservice.nim)
    ##  startType: is one of 
    ##      SERVICE_BOOT_START    # ?? TODO
    ##      SERVICE_SYSTEM_START  # ?? TODO
    ##      SERVICE_DEMAND_START  # start service manually
    ##      SERVICE_AUTO_START    # start service automatically
    ##      SERVICE_DISABLED      # service is disabled
    ## returns true if the service was created successfully, false otherwise.
    # create service
    var service: SC_HANDLE = CreateService( 
        scmManager, # SCM database 
        serviceName.LPCSTR, # name of service 
        serviceDisplayName.LPCSTR, # service name to display 
        SERVICE_ALL_ACCESS, # desired access 
        SERVICE_WIN32_OWN_PROCESS, # service type 
        startType, #SERVICE_DEMAND_START, # start type 
        SERVICE_ERROR_NORMAL, # error control type 
        path.LPCSTR, # path to service's binary 
        "".LPCSTR, # no load ordering group 
        nil.LPDWORD, # no tag identifier 
        "".LPCSTR, # no dependencies 
        nil, # LocalSystem account 
        nil # no password 
    )
    discard service.close()
    if service == 0:
        echo "could not create service: ", GetLastError()
        return false
    else:
        return true

proc startService(scmManager: SC_HANDLE, serviceName: string): bool =
    ## starts a service by its name (*not* serviceDisplayName!)
    ## return true if service started sucessfully, false otherwise
    # TODO support arguments!
    var service: SC_HANDLE = scmManager.getServiceByName(serviceName)
    result = StartService(
        service,
        0, # TODO number of arguments
        nil, # TODO arguments
    ).bool
    discard service.close()


proc stopService(scmManager: SC_HANDLE, serviceName: string): bool =
    ## stops a service by its name (*not* serviceDisplayName!)
    ## return true if service stopped sucessfully, false otherwise
    # TODO check if service is already stopped, or is in SERVICE_STOP_PENDING, if it is then return success / or wait
    # var service: SC_HANDLE = scmManager.getServiceByName(serviceName)
    # result = StopService
    echo "Stop service not implemented yet"

when isMainModule:
    ## Register the service
    var scm = openServiceManager()
    # echo scm.deleteService("ZZZ_SERVICE_NAME4")
    # echo scm.createService("ZZZ_SERVICE_NAME4", "ZZZ_DISPLAY_NAME4", getAppFilename())
    # echo scm.deleteService("SERVICE_NAME3")
    echo scm.createService("SERVICE_NAME3", "SERVICE_NAME3", getAppDir() / "winservice.exe")
    echo scm.startService("SERVICE_NAME3")
    # CloseServiceHandle(schService); 
    echo scm.close() # when we're finished, close the handle to the service mananger

# echo scmManager.deleteService("TEST_SERVICE")
# echo scmManager.deleteService("TEST SERVICE")