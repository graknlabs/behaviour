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

Feature: Attribute Attachment Resolution

  Background: Set up keyspaces for resolution testing

    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | materialised |
      | reasoned     |
    Given materialised keyspace is named: materialised
    Given reasoned keyspace is named: reasoned
    Given for each session, graql define
      """
      define

      person sub entity,
          plays leader,
          plays team-member,
          has string-attribute,
          has unrelated-attribute,
          has sub-string-attribute,
          has age,
          has is-old;

      tortoise sub entity,
          has age,
          has is-old;

      soft-drink sub entity,
          has retailer;

      team sub relation,
          relates leader,
          relates team-member,
          has string-attribute;

      string-attribute sub attribute, value string;
      retailer sub attribute, value string;
      age sub attribute, value long;
      is-old sub attribute, value boolean;
      sub-string-attribute sub string-attribute;
      unrelated-attribute sub attribute, value string;
      ref sub attribute, value long;
      """


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: when a rule copies an attribute from one entity to another, the existing attribute instance is reused
    Given for each session, graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match $x isa person, has string-attribute $y; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match $x isa string-attribute; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once re-attachment of unrelated attributes is resolvable
  Scenario: when multiple rules copy attributes from an entity, they all get resolved
    Given for each session, graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      transfer-attribute-value-to-sub-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has sub-string-attribute $r1;
      };

      transfer-attribute-value-to-unrelated-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has unrelated-attribute $r1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match $x isa person; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match $x isa person, has attribute $y; get;
      """
    # four attributes for each entity
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 6
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once re-attachment of unrelated attributes is resolvable
  Scenario: when a rule copies an attribute value to its sub-attribute, a new attribute concept is inferred
    Given for each session, graql define
      """
      define
      transfer-attribute-value-to-sub-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has sub-string-attribute $r1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match $x isa person, has sub-string-attribute $y; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match $x isa sub-string-attribute; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match $x isa string-attribute; $y isa sub-string-attribute; get;
      """
    # 2 SA instances - one base, one sub hence two answers
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once re-attachment of unrelated attributes is resolvable
  Scenario: when a rule copies an attribute value to an unrelated attribute, a new attribute concept is inferred
    Given for each session, graql define
      """
      define
      transfer-attribute-value-to-unrelated-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has unrelated-attribute $r1;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match $x isa person, has unrelated-attribute $y; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
    Then for graql query
      """
      match $x isa unrelated-attribute; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 1
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once attribute re-attachment is resolvable
  Scenario: when the same attribute is inferred on an entity and relation, both owners are correctly retrieved
    Given for each session, graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      transfer-string-attribute-from-people-to-teams sub rule,
      when {
        $x isa person, has string-attribute $y;
        $z isa team;
      },
      then {
        $z has string-attribute $y;
      };
      """
    Given for each session, graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      (leader:$geX, team-member:$geX) isa team;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match $x has string-attribute $y; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 3
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: a rule can infer an attribute value that did not previously exist in the graph
    Given for each session, graql define
      """
      define
      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given for each session, graql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match $x has retailer 'Ocado'; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
    Then for graql query
      """
      match $x has retailer $r; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 4
    Then for graql query
      """
      match $x has retailer 'Tesco'; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
#    Then materialised and reasoned keyspaces are the same size


  # TODO: re-enable all steps once implicit attribute variables are resolvable
  Scenario: a rule can make a thing own an attribute that had no prior owners
    Given for each session, graql define
      """
      define
      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer $x;
      };
      """
    Given for each session, graql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
#    When materialised keyspace is completed
    Then for graql query
      """
      match $x isa soft-drink, has retailer 'Ocado'; get;
      """
#    Then all answers are correct in reasoned keyspace
    Then answer size in reasoned keyspace is: 2
#    Then materialised and reasoned keyspaces are the same size
