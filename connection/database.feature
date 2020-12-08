#
# Copyright (C) 2020 Grakn Labs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

#noinspection CucumberUndefinedStep
Feature: Connection Database

  Background:
    Given connection has been opened
    Given connection does not have any database

  Scenario: create one database
    When  connection create database:
      | alice |
    Then  connection has database:
      | alice |

  Scenario: create many databases
    When  connection create databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection has databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |


  Scenario: create many databases in parallel
    When  connection create databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection has databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |


  Scenario: delete one database
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection create database:
      | alice |
    When  connection delete database:
      | alice |
    Then  connection does not have database:
      | alice |
    Then  connection does not have any database

  Scenario: connection can delete many databases
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection create databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When  connection delete databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection does not have databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection does not have any database

  Scenario: delete many databases in parallel
      # This step should be rewritten once we can create keypsaces without opening sessions
    Given connection create databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    When  connection delete databases in parallel:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection does not have databases:
      | alice   |
      | bob     |
      | charlie |
      | dylan   |
      | eve     |
      | frank   |

    Then  connection does not have any database


  # TODO: currently this fails in spectacular fashion in 2.0, killing the entire JVM with a segfault (#96)
  @ignore-grakn-2.0
  Scenario: delete a database causes open sessions to fail
    When connection create database:
      | grakn |
    When connection open session for database:
      | grakn |
    When  connection delete database:
      | grakn |
    Then  connection does not have database:
      | grakn |
    Then for each session, open transaction of type; throws exception
      | write |


  # TODO: re-enable when grakn 2.0 supports graql
  @ignore-grakn-2.0
  Scenario: delete a database causes open transactions to fail
    When connection create database:
      | grakn |
    When connection open session for database:
      | grakn |
    When for each session, open transaction of type:
      | write |
    When connection delete database:
      | grakn |
    Then connection does not have database:
      | grakn |
    Then for each transaction, define query; throws exception containing "transaction is closed"
      """
      define person sub entity;
      """

  Scenario: delete a nonexistent database throws an error
    When connection delete database; throws exception
      | grakn |
