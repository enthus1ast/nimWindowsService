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

proc deleteService*(scmManager: SC_HANDLE, serviceName: string): bool = 
    ## deletes a windows service by its ServiceName (*not* display name!)
    var service: SC_HANDLE 
    service = scmManager.OpenService(serviceName.LPCSTR, SERVICE_ALL_ACCESS)
    if service == 0:
        echo "could not open service vor deletion:", GetLastError()
        return false
    result = service.DeleteService().bool
    discard service.CloseServiceHandle()

proc createService*(scmManager: SC_HANDLE, serviceName, serviceDisplayName, path: string): bool =
    ## registers a service in the scmManager
    ##  serviceName: is the internal service name (sc query serviceName)
    ##  serviceDisplayName: is the visible service name (net start serviceDisplayName)
    ##  path: is the absolute path to the service executable
    ## returns true if the service was created successfully, false otherwise.
    # create service
    var service: SC_HANDLE = CreateService( 
        scmManager, # SCM database 
        serviceName.LPCSTR, # name of service 
        serviceDisplayName.LPCSTR, # service name to display 
        SERVICE_ALL_ACCESS, # desired access 
        SERVICE_WIN32_OWN_PROCESS, # service type 
        SERVICE_DEMAND_START, # start type 
        SERVICE_ERROR_NORMAL, # error control type 
        path.LPCSTR, # path to service's binary 
        "".LPCSTR, # no load ordering group 
        nil.LPDWORD, # no tag identifier 
        "".LPCSTR, # no dependencies 
        nil, # LocalSystem account 
        nil # no password 
    )
    discard CloseServiceHandle(service)
    if service == 0:
        echo "could not create service: ", GetLastError()
        return false
    else:
        return true

when isMainModule:
    ## Register the service
    var scm = openServiceManager()
    echo scm.deleteService("ZZZ_SERVICE_NAME4")
    echo scm.createService("ZZZ_SERVICE_NAME4", "ZZZ_DISPLAY_NAME4", getAppFilename())
    # CloseServiceHandle(schService); 
    echo scm.CloseServiceHandle() # when we're finished, close the handle to the service mananger

    
# echo scmManager.deleteService("TEST_SERVICE")
# echo scmManager.deleteService("TEST SERVICE")