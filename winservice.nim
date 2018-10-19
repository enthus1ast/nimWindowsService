#
#
#               nimWindowsService
#        (c) Copyright 2018 David Krause
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## the service code
## a windows service needs to register its main function in the Service control manager
## and also report its status!

# https://docs.microsoft.com/en-us/windows/desktop/api/winsvc/nf-winsvc-controlservice


import winServiceControl
import oldwinapi/windows
#####
import os
#^^^^

var SERVICE_NAME =  "SERVICE_NAME".LPTSTR
var gSvcStatusHandle: SERVICE_STATUS_HANDLE

proc reportSvcStatus(dwCurrentState, dwWin32ExitCode, dwWaitHint: DWORD) =
    var 
        gSvcStatus: SERVICE_STATUS 
        dwCheckPoint: DWORD = 1 # TODO what is this? 
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

proc svcCtrlHandler(dwCtrl: DWORD): WINBOOL {.stdcall.} =
    ## Handle the requested control code. 
    case dwCtrl
    of SERVICE_CONTROL_STOP:
        # ReportSvcStatus
        discard
    of SERVICE_CONTROL_INTERROGATE:
        discard
    else:
        discard

# SERVICE_TABLE_ENTRY* {.final, pure.} = object
# lpServiceName*: LPTSTR
# lpServiceProc*: LPSERVICE_MAIN_FUNCTION
# VOID WINAPI SvcMain( DWORD dwArgc, LPTSTR *lpszArgv )
proc SvcMain(dwArgc: DWORD, lpszArgv: LPTSTR) {.stdcall.} =  #
    gSvcStatusHandle = RegisterServiceCtrlHandler(
        SERVICE_NAME,
        svcCtrlHandler
    )

    #########################
    ## THE SERVICE MAIN     #
    ## YOUR CODE GOES HERE! #
    #########################
    discard
    sleep(10_000)    

var dispatchTable = [
    SERVICE_TABLE_ENTRY(lpServiceName: SERVICE_NAME, lpServiceProc: SvcMain),
    SERVICE_TABLE_ENTRY(lpServiceName: nil, lpServiceProc: nil) # last entry must be nil
]

echo StartServiceCtrlDispatcher( (addr dispatchTable[0]).LPSERVICE_TABLE_ENTRY)
