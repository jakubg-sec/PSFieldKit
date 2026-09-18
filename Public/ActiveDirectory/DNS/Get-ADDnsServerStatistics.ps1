function Get-ADDnsServerStatistics {
    $ServerName = Read-Host "Enter DNS server name"

    if ([string]::IsNullOrWhiteSpace($ServerName)) {
        Write-Host "`nDNS server name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Statistics = Get-DnsServerStatistics `
            -ComputerName $ServerName `
            -ErrorAction Stop

        Write-Host "`nDNS Server Statistics" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan
        Write-Host "Server: $ServerName"
        Write-Host ""

        Write-Host "Time Statistics" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            ServerStartTime                 = $Statistics.TimeStatistics.ServerStartTime
            LastClearTime                   = $Statistics.TimeStatistics.LastClearTime
            TimeSinceLastClear              = $Statistics.TimeStatistics.TimeElapsedSinceLastClearedStatistics
            TimeSinceServerStart            = $Statistics.TimeStatistics.TimeElapsedSinceServerStart
        } | Format-List

        Write-Host "Query Statistics" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            TotalQueries       = $Statistics.Query2Statistics.TotalQueries
            StandardQueries    = $Statistics.Query2Statistics.Standard
            TypeAQueries       = $Statistics.Query2Statistics.TypeA
            TypeAAAAQueries    = $Statistics.Query2Statistics.TypeAll
            PTRQueries         = $Statistics.Query2Statistics.TypePtr
            MXQueries          = $Statistics.Query2Statistics.TypeMx
            NSQueries          = $Statistics.Query2Statistics.TypeNs
            SRVQueries         = $Statistics.Query2Statistics.TypeSrv
            SOAQueries         = $Statistics.Query2Statistics.TypeSoa
            TXTQueries         = $Statistics.Query2Statistics.TypeOther
        } | Format-List

        Write-Host "Transport Statistics" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            UDPQueries          = $Statistics.QueryStatistics.UdpQueries
            TCPQueries          = $Statistics.QueryStatistics.TcpQueries
            UDPQueriesSent      = $Statistics.QueryStatistics.UdpQueriesSent
            TCPQueriesSent      = $Statistics.QueryStatistics.TcpQueriesSent
            UDPResponses        = $Statistics.QueryStatistics.UdpResponses
            TCPResponses        = $Statistics.QueryStatistics.TcpResponses
            UDPResponsesReceived = $Statistics.QueryStatistics.UdpResponsesReceived
            TCPResponsesReceived = $Statistics.QueryStatistics.TcpResponsesReceived
        } | Format-List

        Write-Host "Recursion Statistics" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            QueriesRecursed        = $Statistics.RecursionStatistics.QueriesRecursed
            TotalQuestionsRecursed = $Statistics.RecursionStatistics.TotalQuestionsRecursed
            Forwards               = $Statistics.RecursionStatistics.Forwards
            ForwardResponses       = $Statistics.RecursionStatistics.ResponseFromForwarder
            RecursionFailures      = $Statistics.RecursionStatistics.RecursionFailure
            Timeouts               = $Statistics.RecursionStatistics.TimedoutQueries
            ServerFailures         = $Statistics.RecursionStatistics.ServerFailure
            Responses              = $Statistics.RecursionStatistics.Responses
        } | Format-List

        Write-Host "DNS Response Errors" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            NoError           = $Statistics.ErrorStatistics.NoError
            NxDomain          = $Statistics.ErrorStatistics.NxDomain
            ServerFailure     = $Statistics.ErrorStatistics.ServFail
            Refused           = $Statistics.ErrorStatistics.Refused
            NotAuthoritative  = $Statistics.ErrorStatistics.NotAuthoritative
            NotImplemented    = $Statistics.ErrorStatistics.NotImpl
            FormError         = $Statistics.ErrorStatistics.FormError
            NotZone           = $Statistics.ErrorStatistics.NotZone
            UnknownError      = $Statistics.ErrorStatistics.UnknownError
        } | Format-List

        Write-Host "Dynamic Update Statistics" -ForegroundColor Cyan
        Write-Host "-------------------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            UpdatesReceived      = $Statistics.UpdateStatistics.Received
            UpdatesCompleted     = $Statistics.UpdateStatistics.Completed
            SecureUpdateSuccess  = $Statistics.UpdateStatistics.SecureSuccess
            SecureUpdateFailure  = $Statistics.UpdateStatistics.SecureFailure
            UpdatesRefused       = $Statistics.UpdateStatistics.Refused
            AccessDenied         = $Statistics.UpdateStatistics.RefusedAccessDenied
            ForwardedUpdates     = $Statistics.UpdateStatistics.Forwards
            UpdateTimeouts       = $Statistics.UpdateStatistics.Timeout
        } | Format-List

        Write-Host "DNSSEC Statistics" -ForegroundColor Cyan
        Write-Host "-----------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            SuccessfulValidations = $Statistics.DnssecStatistics.SuccessfulValidations
            FailedValidations     = $Statistics.DnssecStatistics.FailedValidations
            RecursionFailures     = $Statistics.DnssecStatistics.RecursionFailures
        } | Format-List
    }
    catch {
        Write-Host "`nFailed to retrieve DNS server statistics." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}