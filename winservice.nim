#
#
#               nimWindowsService
#        (c) Copyright 2018 David Krause
#
#    See the file "LICENSE.txt", included in this
#    distribution, for details about the copyright.
#
## the service code
## a windows service needs to register its main function in the Service control manager
## and also report its status!

# https://docs.microsoft.com/en-us/windows/desktop/api/winsvc/nf-winsvc-controlservice


import winim/lean

type ServiceMain = proc(gSvcStatus: SERVICE_STATUS)

var SERVICE_NAME =  "SERVICE_NAME2_BAA".LPTSTR
var gSvcStatusHandle: SERVICE_STATUS_HANDLE
var gSvcStatus: SERVICE_STATUS 

proc reportSvcStatus*(dwCurrentState, dwWin32ExitCode, dwWaitHint: DWORD) =
    var dwCheckPoint: DWORD = 1 # TODO what is this? 
    gSvcStatus.dwCurrentState = dwCurrentState
    gSvcStatus.dwWin32ExitCode = dwWin32ExitCode
    gSvcStatus.dwWaitHint = dwWaitHint
    if dwCurrentState == SERVICE_START_PENDING:
        gSvcStatus.dwControlsAccepted = 0
    else:
        gSvcStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP

    if dwCurrentState == SERVICE_RUNNING or dwCurrentState == SERVICE_STOPPED:
        gSvcStatus.dwCheckPoint = 0
    else:
        gSvcStatus.dwCheckPoint = dwCheckPoint
        dwCheckPoint.inc()
    
    # Report the status of the service to the SCM.
    echo "SetServiceStatus: " & $SetServiceStatus(gSvcStatusHandle, addr gSvcStatus)

proc svcCtrlHandler(dwCtrl: DWORD) {.stdcall.} =
    ## Handle the requested control code. 
    case dwCtrl
    of SERVICE_CONTROL_STOP:
        # Signal the service to stop 
        # TODO we must stop OUR code somehow!
        reportSvcStatus(SERVICE_STOP_PENDING, NO_ERROR, 10_000) # we think we can stop the service in 10 seconds
    of SERVICE_CONTROL_INTERROGATE:
        discard
    else:
        discard

template wrapServiceMain*(mainProc: ServiceMain): LPSERVICE_MAIN_FUNCTION = 
    ## wraps a nim proc in a LPSERVICE_MAIN_FUNCTION
    proc serviceMainFunction(dwArgc: DWORD, lpszArgv: ptr LPTSTR) {.stdcall.} =
        gSvcStatusHandle = RegisterServiceCtrlHandler(
            SERVICE_NAME,
            svcCtrlHandler
        )
        gSvcStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS
        gSvcStatus.dwServiceSpecificExitCode = 0
        reportSvcStatus(SERVICE_RUNNING, NO_ERROR, 0)   
        mainProc(gSvcStatus) # call the wrapped proc
        reportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0) # we have to report back when we stopped!
    serviceMainFunction

# proc addService*(services: Services, serviceName: string, serviceMain: ServiceMain) =
#     ## High level proc to register services
#     discard

when isMainModule:
    import times, os
    proc serviceMain(gSvcStatus: SERVICE_STATUS) =
        ## a service main
        ## use gScvStatus to check if we should stop periodically!
        var fh = open("C:/servicelog.txt", fmAppend)
        fh.write("SERVICE STARTED\n")
        fh.flushFile()
        while gSvcStatus.dwCurrentState == SERVICE_RUNNING:
            reportSvcStatus(SERVICE_RUNNING, NO_ERROR, 0)
            fh.write($epochTime() & "\n")
            fh.flushFile()
            sleep(1_000)   
        fh.write("SERVICE CLOSED BY MANAGER!\n")
        fh.flushFile()
        # reportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0) # we have to report back when we stopped!

    var wrapped = wrapServiceMain(serviceMain)
    var dispatchTable = [
        # SERVICE_TABLE_ENTRY(lpServiceName: SERVICE_NAME, lpServiceProc: SvcMain),
        SERVICE_TABLE_ENTRY(lpServiceName: SERVICE_NAME, lpServiceProc: wrapped),
        SERVICE_TABLE_ENTRY(lpServiceName: nil, lpServiceProc: nil) # last entry must be nil
    ]

    echo StartServiceCtrlDispatcher( (addr dispatchTable[0]).LPSERVICE_TABLE_ENTRY)