@single_cartridge @domain_required @cartridge_storage_user_required
Feature: Single Cartridge Tests

  # Need to keep these outlines duplicated until we update cucumber to allow tagged examples

  @init
  Scenario Outline: Cartridge Commands
    When the <type> cartridge is <command>
    Then the <type> cartridge should be <status>

    Examples:
      | type            | command   | status  |
      | mysql           | added     | running |

  Scenario Outline: Cartridge Commands
    Given we have a <state> mysql cartridge
    When the mysql cartridge is <command>
    Then the mysql cartridge should be <status>

    Examples:
      | state   | command   | status  |
      | running | restarted | running |
      | running | stopped   | stopped |
      | stopped | started   | running |

  Scenario Outline: Cartridge List
    When we list cartridges
    Then the list should contain the cartridge <cart> with display name

    Examples:
      | cart    |
      | php     |
      | mongodb |
      | cron    |


#  Commenting this out for US2438
#  Scenario Outline: Cartridge Storage
#    Given we have a running mysql-5.1 cartridge
#    When we <action> storage for the mysql-5.1 cartridge
#    Then the additional cartridge storage amount should be <total>
#
#    Examples:
#      | action     | total |
#      | show       | None  |
#      | add 5GB    | 5GB   |
#      | remove 3GB | 2GB   |
#      | set 4GB    | 4GB   |
