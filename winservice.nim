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
## and also 

# https://docs.microsoft.com/en-us/windows/desktop/api/winsvc/nf-winsvc-controlservice


import winServiceControl
import oldwinapi/windows
#####
import os
#^^^^
# SERVICE_TABLE_ENTRY* {.final, pure.} = object
# lpServiceName*: LPTSTR
# lpServiceProc*: LPSERVICE_MAIN_FUNCTION

# VOID WINAPI SvcMain( DWORD dwArgc, LPTSTR *lpszArgv )
proc SvcMain(dwArgc: DWORD, lpszArgv: LPTSTR) {.stdcall.} =  #
    ## THE SERVICE MAIN
    discard
    sleep(10_000)

proc SvcCtrlHandler(dwCtrl: DWORD) {.stdcall.} =
    ## Handle the requested control code. 
    case dwCtrl
    of SERVICE_CONTROL_STOP:
        # ReportSvcStatus
        discard
    of SERVICE_CONTROL_INTERROGATE:
        discard
    else:
        discard
    

var dispatchTable = [
    SERVICE_TABLE_ENTRY(lpServiceName: "SERVICE_NAME".LPTSTR, lpServiceProc: SvcMain),
    SERVICE_TABLE_ENTRY(lpServiceName: nil, lpServiceProc: nil) # last entry must be nil
]

echo StartServiceCtrlDispatcher( (addr dispatchTable[0]).LPSERVICE_TABLE_ENTRY)
