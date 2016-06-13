# Quality Center Controller

    +-----+---------------+----------+-------------+-------------+-----------------------------+
    | Id  | Priority      | Status   | Detected By | Assigned To | Summary                     |
    +-----+---------------+----------+-------------+-------------+-----------------------------+
    | 19  | 3-Significant | Rejected | james       | gaving      | Field abc does not display  |
    | 34  |    4-Minor    | Closed   | steven      | george      | Field abc does not display  |
    | 37  | 3-Significant | Closed   | steven      | george      | Field abc does not display  |
    | 39  | 3-Significant | Closed   | steven      | george      | Field abc does not display  |
    | 40  | 3-Significant | Closed   | steven      | george      | Field abc does not display  |
    | 44  | 3-Significant | Closed   | steven      | george      | Field abc does not display  |
    | 57  |    4-Minor    | Fixed    | steven      | gaving      | Field abc does not display  |
    | 71  |  2-Essential  | Open     | george      | gaving      | Field abc does not display  |
    | 83  | 3-Significant | Rejected | george      | gaving      | Field abc does not display  |
    | 145 | 3-Significant | Fixed    | george      | gaving      | Field abc does not display  |
    +-----+---------------+----------+---------------------+-------------+---------------------+

## Requirements

* 32-bit Ruby*
* QC 11.52
* Install HP ALM Connectivity Tool (Help -> ALM Tools -> HP ALM Connectivity)

Note a 32-bit version of ruby is required since the OTAClient.dll is a 32-bit dll.

## Installation

    * gem install qcc --local qcc-1.0.0.gem

## Usage

    Usage: qcc [options]

    List:
            --list-all                   All defects
            --list-closed                Closed defects
            --list-fixed                 Fixed defects
            --list-open                  Open defects
            --list-reopen                Reopen defects
            --list-new                   New defects
            --list-rejected              Rejected defects

    Assigned:
            --assigned [USER1,USER2,...] Assigned to user

    Action:
        -c, --mark-closed [DEFECT]       Close defect
        -f, --mark-fixed [DEFECT]        Fixed defect
        -n, --mark-new [DEFECT]          New defect
        -o, --mark-open [DEFECT]         Open defect
        -r, --mark-rejected [DEFECT]     Reject defect

    Other:
        -i, --info [DEFECT]              Show info about defect
        -d, --download                   Download the attachments when viewing defect info
        -h, --help                       Show this message
            --version                    Show version

## Developing

* gem install bundler
* bundle install
* bundle exec qcc
