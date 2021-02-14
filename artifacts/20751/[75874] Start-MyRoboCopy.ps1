function Start-MyRoboCopy {
param (
        $SourceDir,
        $DestinationDir,
        $Files = "*.*",
        $Threads = 10,
        $Retry = 5,
        $WaitSecondsbetweenFailure = 15,
        $LogFile = ("$home\documents\MyRobocopyLog-{0:yyyy-MM-dd}.txt" -f (Get-Date)),
        [Switch]$SmallFiles
        )

if (Test-Path -Path $SourceDir)
    {
        # /E :: copy subdirectories, including Empty ones.
        # /ZB :: use restartable mode; if access denied use Backup mode.
        # /J :: copy using unbuffered I/O (recommended for large files).
        # /COPY:copyflag[s] :: what to COPY for files (default is /COPY:DAT).
                     # (copyflags : D=Data, A=Attributes, T=Timestamps)
        # /DCOPY:copyflag[s] :: what to COPY for directories (default is /DCOPY:DA).
                     # (copyflags : D=Data, A=Attributes, T=Timestamps).
        # /R:n :: number of Retries on failed copies: default 1 million.
        # /W:n :: Wait time between retries: default is 30 seconds.
        # /DCOPY:copyflag[s] :: what to COPY for directories (default is /DCOPY:DA).
                     # (copyflags : D=Data, A=Attributes, T=Timestamps).
        # /TEE :: output to console window, as well as the log file.
        # /LOG+:file :: output status to LOG file (append to existing log).
        
    if ($SmallFiles)
        {
            # buffered I/O
            robocopy $SourceDir $DestinationDir $Files /E /ZB /Copy:DAT /DCopy:DA `
            /MT:$Threads /R:$Retry /W:$WaitSecondsbetweenFailure /V /ETA /LOG+:$LogFile /TEE
        }
    else
        {
            # Unbuffered I/O
            robocopy $SourceDir $DestinationDir $Files /E /ZB /J /Copy:DAT /DCopy:DA `
            /MT:$Threads /R:$Retry /W:$WaitSecondsbetweenFailure /V /ETA /LOG+:$LogFile /TEE
    }
    }
else
    {
        "Cannot connect to $SourceDir"
    }

}