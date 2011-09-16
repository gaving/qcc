# Quality Center Controller

## Installation

    gem install qcc

## Usage

    Usage: qcc [options]

    List options:
            --list-all                   All bugs
            --list-closed                Closed bugs
            --list-fixed                 Fixed bugs
            --list-open                  Open bugs
            --list-reopen                Reopen bugs
            --list-new                   New bugs

    Action options:
        -c, --mark-closed [BUG]          Close bug
        -f, --mark-fixed [BUG]           Fixed bug
        -n, --mark-new [BUG]             New bug
        -o, --mark-open [BUG]            Open bug

    Other options:
        -i, --info [BUG]                 Show info about bug
        -h, --help                       Show this message
            --version                    Show version
