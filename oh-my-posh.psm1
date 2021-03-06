#requires -Version 2 -Modules posh-git

. "$PSScriptRoot\Themes\Tools.ps1"
. "$PSScriptRoot\defaults.ps1"

$global:ThemeSettings = New-Object -TypeName PSObject -Property @{
    Theme                            = 'Agnoster'
    GitBranchSymbol                  = [char]::ConvertFromUtf32(0xE0A0)
    FailedCommandSymbol              = [char]::ConvertFromUtf32(0x2A2F)
    TruncatedFolderSymbol            = '..'
    BeforeStashSymbol                = '{'
    AfterStashSymbol                 = '}'
    DelimSymbol                      = '|'
    LocalWorkingStatusSymbol         = '!'
    LocalStagedStatusSymbol          = '~'
    LocalDefaultStatusSymbol         = ''
    BranchUntrackedSymbol            = [char]::ConvertFromUtf32(0x2262)
    BranchIdenticalStatusToSymbol    = [char]::ConvertFromUtf32(0x2263)
    BranchAheadStatusSymbol          = [char]::ConvertFromUtf32(0x2191)
    BranchBehindStatusSymbol         = [char]::ConvertFromUtf32(0x2193)
    ElevatedSymbol                   = [char]::ConvertFromUtf32(0x26A1)
    GitDefaultColor                  = [ConsoleColor]::DarkGreen
    GitLocalChangesColor             = [ConsoleColor]::DarkYellow
    GitNoLocalChangesAndAheadColor   = [ConsoleColor]::DarkMagenta
    PromptForegroundColor            = [ConsoleColor]::White
    PromptHighlightColor             = [ConsoleColor]::DarkBlue
    DriveForegroundColor             = [ConsoleColor]::DarkBlue
    PromptBackgroundColor            = [ConsoleColor]::DarkBlue
    PromptSymbolColor                = [ConsoleColor]::White
    SessionInfoBackgroundColor       = [ConsoleColor]::Magenta
    SessionInfoForegroundColor       = [ConsoleColor]::White
    CommandFailedIconForegroundColor = [ConsoleColor]::DarkRed
    AdminIconForegroundColor         = [ConsoleColor]::DarkYellow
    WithBackgroundColor              = [ConsoleColor]::DarkRed
    WithForegroundColor              = [ConsoleColor]::White
    ErrorCount                       = 0
}

<#
        .SYNOPSIS
        Method called at each launch of Powershell

        .DESCRIPTION
        Sets up things needed in each console session, aside from prompt
#>
function Start-Up
{
    if(Test-Path -Path ~\.last)
    {
        (Get-Content -Path ~\.last) | Set-Location
        Remove-Item -Path ~\.last
    }

    # Makes git diff work
    $env:TERM = 'msys'

    if(Get-Module -Name Posh-Git)
    {
        Start-SshAgent -Quiet
    }

    Set-Prompt
}

<#
        .SYNOPSIS
        Generates the prompt before each line in the console
#>
function Set-Prompt
{
    Import-Module $PSScriptRoot\Themes\$($sl.Theme).psm1

    function global:prompt
    {
        $lastCommandFailed = $global:error.Count -gt $sl.ErrorCount
        $sl.ErrorCount = $global:error.Count

        #Start the vanilla posh-git when in a vanilla window, else: go nuts
        if(Test-IsVanillaWindow)
        {
            Write-Host -Object ($pwd.ProviderPath) -NoNewline
            Write-VcsStatus
            $global:LASTEXITCODE = !$lastCommandFailed
            return '> '
        }

        Write-Theme -lastCommandFailed $lastCommandFailed
        return ' '
    }
}

function global:Write-WithPrompt()
{
    param(
        [string]
        $command
    )

    $lastCommandFailed = $global:error.Count -gt $sl.ErrorCount
    $sl.ErrorCount = $global:error.Count

    if(Test-IsVanillaWindow)
    {
        Write-ClassicPrompt -command $command 
        return
    }
    
    Write-Theme -lastCommandFailed $lastCommandFailed -with $command
    Write-Host ' ' -NoNewline
}

function Show-ThemeColors
{
    Write-Host -Object ''
    Write-ColorPreview -text 'GitDefaultColor                  ' -color $sl.GitDefaultColor
    Write-ColorPreview -text 'GitLocalChangesColor             ' -color $sl.GitLocalChangesColor
    Write-ColorPreview -text 'GitNoLocalChangesAndAheadColor   ' -color $sl.GitNoLocalChangesAndAheadColor
    Write-ColorPreview -text 'PromptForegroundColor            ' -color $sl.PromptForegroundColor
    Write-ColorPreview -text 'PromptBackgroundColor            ' -color $sl.PromptBackgroundColor
    Write-ColorPreview -text 'PromptSymbolColor                ' -color $sl.PromptSymbolColor
    Write-ColorPreview -text 'PromptHighlightColor             ' -color $sl.PromptHighlightColor
    Write-ColorPreview -text 'SessionInfoBackgroundColor       ' -color $sl.SessionInfoBackgroundColor
    Write-ColorPreview -text 'SessionInfoForegroundColor       ' -color $sl.SessionInfoForegroundColor
    Write-ColorPreview -text 'CommandFailedIconForegroundColor ' -color $sl.CommandFailedIconForegroundColor
    Write-ColorPreview -text 'AdminIconForegroundColor         ' -color $sl.AdminIconForegroundColor
    Write-ColorPreview -text 'WithBackgroundColor              ' -color $sl.WithBackgroundColor
    Write-ColorPreview -text 'WithForegroundColor              ' -color $sl.WithForegroundColor
    Write-Host -Object ''
}

function Write-ColorPreview
{
    param
    (
        [string]
        $text,
        [ConsoleColor]
        $color
    )

    Write-Host -Object $text -NoNewline
    Write-Host -Object '       ' -BackgroundColor $color
}

function Show-Colors
{
    for($i = 0; $i -lt 16; $i++)
    {
        $color = [ConsoleColor]$i
        Write-Host -Object $color -BackgroundColor $i
    }
}

function Show-Themes
{
    Write-Host ''
    Get-ChildItem -Path "$PSScriptRoot\Themes\*" -Include '*.psm1' -Exclude Tools.ps1 | Sort-Object Name | ForEach-Object -Process {write-Host "- $($_.BaseName)"} 
    Write-Host ''
    
}

function Set-Theme
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $name
    )

    if (Test-Path "$PSScriptRoot\Themes\$($name).psm1")
    {
        $sl.Theme = $name
    }
    else
    {
        Write-Host ''
        Write-Host "Theme $name not found. Available themes are:"
        Show-Themes
    }

    Set-Prompt
}


$sl = $global:ThemeSettings #local settings
$sl.ErrorCount = $global:error.Count
Start-Up # Executes the Start-Up function, better encapsulation
