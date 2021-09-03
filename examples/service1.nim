# A simple demo service
import ../winservice
import winim/lean
import times, os

const SERVICE_NAME = "ZZZ_TEST_SERVICE_2"

proc serviceMain(gSvcStatus: SERVICE_STATUS) =
    ## a service main
    ## use gScvStatus to check if we should stop periodically!
    var fh = open("C:/servicelog.txt", fmAppend)
    fh.write("SERVICE (1) STARTED\n")
    fh.flushFile()
    while gSvcStatus.dwCurrentState == SERVICE_RUNNING:
        reportSvcStatus(SERVICE_RUNNING, NO_ERROR, 0)
        fh.write($epochTime() & "\n")
        fh.flushFile()
        sleep(1_000)   
    fh.write("SERVICE CLOSED BY MANAGER!\n")
    fh.flushFile()
    reportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0) # we have to report back when we stopped!

when isMainModule:
    var dispatchTable = [
        SERVICE_TABLE_ENTRY(lpServiceName: SERVICE_NAME, lpServiceProc: wrapServiceMain(serviceMain)),
        SERVICE_TABLE_ENTRY(lpServiceName: nil, lpServiceProc: nil) # last entry must be nil
    ]

    echo StartServiceCtrlDispatcher( (addr dispatchTable[0]).LPSERVICE_TABLE_ENTRY)
    