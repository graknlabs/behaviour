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

Feature: Graql Reasoning Explanation

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_explanation |
    Given transaction is initialised

  Scenario: atomic query has lookup explanation

  Verify the code path for atomic queries produces correct explanation and pattern.

    Given graql define
      """
      define
      name sub attribute,
          value string;

      person sub entity,
        key name;
      """

    When graql insert
      """
      insert
      $p isa person, has name "Alice";
      """

    Then get answers of graql query
      """
      match $p isa person; get;
      """

    Then concept identifiers are
      |     | check | value       |
      | AL  | key   | name:Alice  |

    Then uniquely identify answer concepts
      | p  |
      | AL |

    Then answers contain explanation tree
      |   | children | vars | identifiers | explanation | pattern                                  |
      | 0 | -        | p    | AL          | lookup      | { $p isa person; $p id <answer.p.id>; }; |

  Scenario: relation has lookup explanation
    Given graql define
      """
      define
      name sub attribute,
          value string;

      location sub entity,
          abstract,
          key name,
          plays superior,
          plays subordinate;

      area sub location;
      city sub location;
      country sub location;

      location-hierarchy sub relation,
          relates superior,
          relates subordinate;
      """

    When graql insert
      """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      (superior: $cit, subordinate: $ar) isa location-hierarchy;
      """

    Then get answers of graql query
      """
      match
      $k isa area, has name $n;
      (superior: $l, subordinate: $k) isa location-hierarchy;
      get;
      """

    Then concept identifiers are
      |     | check | value             |
      | KC  | key   | name:King's Cross |
      | LDN | key   | name:London       |
      | KCn | value | name:King's Cross |

    Then uniquely identify answer concepts
      | k  | l   | n   |
      | KC | LDN | KCn |

    Then answers contain explanation tree
      |   | children | vars    | identifiers  | explanation | pattern                                                                                                                                                  |
      | 0 | -        | k, l, n | KC, LDN, KCn | lookup      | { $k isa area; $k has name $n; (superior: $l, subordinate: $k) isa location-hierarchy; $k id <answer.k.id>; $n id <answer.n.id>; $l id <answer.l.id>; }; |

  Scenario: non-atomic query has lookup explanation with the full pattern

    Verify the code path for non-atomic queries produces correct explanation and pattern.

    Given graql define
      """
      define
      name sub attribute,
          value string;

      location sub entity,
          abstract,
          key name,
          plays superior,
          plays subordinate;

      area sub location;
      city sub location;
      country sub location;

      location-hierarchy sub relation,
          relates superior,
          relates subordinate;
      """

    When graql insert
      """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      $cou isa country, has name "UK";
      (superior: $cit, subordinate: $ar) isa location-hierarchy;
      (superior: $cou, subordinate: $cit) isa location-hierarchy;
      """

    Then get answers of graql query
      """
      match
      $k isa area, has name $n;
      (superior: $l, subordinate: $k) isa location-hierarchy;
      (superior: $u, subordinate: $l) isa location-hierarchy;
      get;
      """

    Then concept identifiers are
      |     | check | value             |
      | KC  | key   | name:King's Cross |
      | LDN | key   | name:London       |
      | UK  | key   | name:UK           |
      | KCn | value | name:King's Cross |

    Then uniquely identify answer concepts
      | k  | l   | u  | n   |
      | KC | LDN | UK | KCn |

    Then answers contain explanation tree
      |   | children | vars       | identifiers       | explanation | pattern                                                                                                                                                                                                                                |
      | 0 | -        | k, l, u, n | KC, LDN, UK, KCn  | lookup      | { $k isa area; $k has name $n; (superior: $l, subordinate: $k) isa location-hierarchy; (superior: $u, subordinate: $l) isa location-hierarchy; $u id <answer.u.id>; $l id <answer.l.id>; $k id <answer.k.id>; $n id <answer.n.id>; };  |

  Scenario: a query containing a negation has a negation explanation

    A negation explanation shows the resolution that occurred. It contains the pattern for the lookup that was performed,
    indicating that this lookup was then checked against the negation to verify that it satisfied the query.

    Given graql define
      """
      define

      name sub attribute,
          value string;

      company-id sub attribute,
          value long;

      company sub entity,
          key company-id,
          has name;
      """

    When graql insert
      """
      insert
      $c1 isa company, has company-id 0;
      $c1 has name $n1; $n1 "the-company";
      $c2 isa company, has company-id 1;
      $c2 has name $n2; $n2 "another-company";
      """

    Then get answers of graql query
      """
      match $com isa company, has name $n; not { $n "the-company"; }; get;
      """

    Then concept identifiers are
      |      | check | value                |
      | ACO  | key   | company-id:1         |
      | N    | value | name:another-company |

    Then uniquely identify answer concepts
      | com | n |
      | ACO | N |

    Then answers contain explanation tree
      |   | children  | vars    | identifiers | explanation | pattern                                                                                                                   |
      | 0 | 1         | com, n  | ACO, N      | negation    | { $com isa company; $com has name $n; $com id <answer.com.id>; $n id <answer.n.id>; not { { $n == "the-company"; }; }; }; |
      | 1 | -         | com, n  | ACO, N      | lookup      | { $com isa company; $com has name $n; $com id <answer.com.id>; $n id <answer.n.id>; };                                    |

  Scenario: a query containing a disjunction has a disjunctive explanation

    Ids in the answer's pattern should sit outside the disjunction, this makes the disjunction valid as it provides outer scope variables for the disjunction to bind to.
    The explanation beneath should explain the disjunctive clause that was used to provide the original answer.

    Given graql define
      """
      define

      name sub attribute,
          value string;

      company-id sub attribute,
          value long;

      company sub entity,
          key company-id,
          has name;
      """

    When graql insert
      """
      insert
      $c2 isa company, has company-id 1;
      $c2 has name $n2; $n2 "another-company";
      """

    Then get answers of graql query
      """
      match $com isa company;
      {$com has name $n1; $n1 "the-company";} or {$com has name $n2; $n2 "another-company";};
      get;
      """

    Then concept identifiers are
      |      | check | value                |
      | ACO  | key   | company-id:1         |
      | N2   | value | name:another-company |

    Then uniquely identify answer concepts
      | com |
      | ACO |

    Then answers contain explanation tree
      |   | children  | vars    | identifiers | explanation | pattern                                                                                                                                                           |
      | 0 | 1         | com     | ACO         | disjunction | { $com id <answer.com.id>; { $com isa company; $com has name $n1; $n1 == "the-company";} or {$com isa company; $com has name $n2; $n2 == "another-company";}; };  |
      | 1 | -         | com, n2 | ACO, N2     | lookup      | { $com isa company; $com has name $n2; $n2 == "another-company"; $com id <answer.com.id>; $n2 id <answer.n2.id>; };                                               |

  Scenario: a query containing a nested disjunction has a single disjunctive explanation due to DNF

    Due to the use of Disjunctive Normal Form, the answer's pattern should contain only one disjunction with ids outside as the outer scope.
    The explanation beneath should explain the disjunctive clause that was used to provide the original answer.

    Given graql define
      """
      define

      name sub attribute,
          value string;

      company-id sub attribute,
          value long;

      company sub entity,
          key company-id,
          has name;
      """

    When graql insert
      """
      insert
      $c2 isa company, has company-id 1;
      $c2 has name $n2; $n2 "another-company";
      """

    Then get answers of graql query
      """
      match $com isa company;
      {$com has name $n1; $n1 "the-company";} or {$com has name $n2; {$n2 "another-company";} or {$n2 "third-company";};};
      get;
      """

    Then concept identifiers are
      |      | check | value                |
      | ACO  | key   | company-id:1         |
      | N2   | value | name:another-company |

    Then uniquely identify answer concepts
      | com |
      | ACO |

    Then answers contain explanation tree
      |   | children  | vars    | identifiers | explanation | pattern                                                                                                                                                                                                                             |
      | 0 | 1         | com     | ACO         | disjunction | { $com id <answer.com.id>; { $com isa company; $com has name $n1; $n1 == "the-company";} or {$com isa company; $com has name $n2; $n2 == "another-company";} or {$com isa company; $com has name $n2; $n2 == "third-company";}; };  |
      | 1 | -         | com, n2 | ACO, N2     | lookup      | { $com isa company; $com has name $n2; $n2 == "another-company"; $com id <answer.com.id>; $n2 id <answer.n2.id>; };                                                                                                                 |
