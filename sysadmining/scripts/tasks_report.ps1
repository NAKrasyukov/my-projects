# Путь к файлам
$serversFile = "C:\1temp\servers.txt"
$outputFile  = "C:\1temp\tasks_report.csv"

# Читаем список серверов
$servers = Get-Content $serversFile
$results = @()

foreach ($server in $servers) {

    Write-Host "Обработка сервера $server ..." -ForegroundColor Cyan

    try {

        $tasks = Invoke-Command -ComputerName $server -ScriptBlock {

            $allTasks = Get-ScheduledTask | Where-Object {
                $_.TaskPath -notlike "\Microsoft\*"
            }

            foreach ($task in $allTasks) {

                $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath

                foreach ($trigger in $task.Triggers) {

                    $triggerType = $trigger.TriggerType

                    # Время запуска
                    $startTime = $trigger.StartBoundary

                    # Повторение
                    $repetitionInterval = if ($trigger.Repetition.Interval) {
                        $trigger.Repetition.Interval
                    } else { "" }

                    $repetitionDuration = if ($trigger.Repetition.Duration) {
                        $trigger.Repetition.Duration
                    } else { "" }

                    [PSCustomObject]@{
                        TaskName           = $task.TaskName
                        TriggerType        = $triggerType
                        StartTime          = $startTime
                        RepetitionInterval = $repetitionInterval
                        RepetitionDuration = $repetitionDuration
                        NextRunTime        = $taskInfo.NextRunTime
                        LastRunTime        = $taskInfo.LastRunTime
                        Status             = $task.State
                        Action             = ($task.Actions | ForEach-Object { $_.Execute }) -join "; "
                    }
                }
            }
        }

        foreach ($task in $tasks) {
            $task | Add-Member -NotePropertyName Server -NotePropertyValue $server
            $results += $task
        }

    }
    catch {
        Write-Warning "Ошибка подключения к $server"
        $results += [PSCustomObject]@{
            Server              = $server
            TaskName            = "ERROR"
            TriggerType         = ""
            StartTime           = ""
            RepetitionInterval  = ""
            RepetitionDuration  = ""
            NextRunTime         = ""
            LastRunTime         = ""
            Status              = $_.Exception.Message
            Action              = ""
        }
    }
}

$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Готово. Результат сохранён в $outputFile" -ForegroundColor Green