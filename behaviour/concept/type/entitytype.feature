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

Feature: Concept Entity Type

  Background:
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection does not have any keyspace
    Given connection create keyspace: grakn
    Given connection open session for keyspace: grakn
    Given session opens transaction of type: write

  Scenario: Create a new entity type
    When put entity type: person
    Then entity(person) is null: false
    Then entity(person) get supertype: entity
    When transaction commits
    When session opens transaction of type: read
    Then entity(person) is null: false
    Then entity(person) get supertype: entity

  Scenario: Change the label of an entity type
    When put entity type: person
    Then entity(person) is null: false
    Then entity(person) get label: person
    When entity(person) set label: horse
    Then entity(horse) is null: false
    Then entity(horse) get label: horse
    When transaction commits
    When session opens transaction of type: write
    Then entity(horse) is null: false
    Then entity(horse) get label: horse
    When entity(horse) set label: animal
    Then entity(animal) is null: false
    Then entity(animal) get label: animal
    When transaction commits
    When session opens transaction of type: read
    Then entity(animal) is null: false
    Then entity(animal) get label: animal

  Scenario: Set an entity type to be abstract
    When put entity type: person
    When entity(person) set abstract: true
    Then entity(person) is abstract: true
    Then entity(person) creates instance successfully: false
    When transaction commits
    When session opens transaction of type: read
    Then entity(person) is abstract: true
    Then entity(person) creates instance successfully: false

  Scenario: Make an entity type subtype another entity type
    When put entity type: man
    When put entity type: person
    When entity(man) set supertype: person
    Then entity(man) is null: false
    Then entity(person) is null: false
    Then entity(man) get supertype: person
    Then entity(person) get supertype: entity
    When transaction commits
    When session opens transaction of type: read
    Then entity(man) is null: false
    Then entity(person) is null: false
    Then entity(man) get supertype: person
    Then entity(person) get supertype: entity

  Scenario: Create a hierarchy of entity types subtyping each other
    When put entity type: man
    When put entity type: woman
    When put entity type: person
    When put entity type: cat
    When put entity type: animal
    When entity(man) set supertype: person
    When entity(woman) set supertype: person
    When entity(person) set supertype: animal
    When entity(cat) set supertype: animal
    Then entity(man) get supertype: person
    Then entity(woman) get supertype: person
    Then entity(person) get supertype: animal
    Then entity(cat) get supertype: animal
    Then entity(man) get supertypes contain:
      | man    |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | woman  |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | person |
      | animal |
    Then entity(cat) get supertypes contain:
      | cat    |
      | animal |
    Then entity(man) get subtypes contain:
      | man |
    Then entity(woman) get subtypes contain:
      | woman |
    Then entity(person) get subtypes contain:
      | person |
      | man    |
      | woman  |
    Then entity(cat) get subtypes contain:
      | cat |
    Then entity(animal) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |
    When transaction commits
    When session opens transaction of type: read
    Then entity(man) get supertype: person
    Then entity(woman) get supertype: person
    Then entity(person) get supertype: animal
    Then entity(cat) get supertype: animal
    Then entity(man) get supertypes contain:
      | man    |
      | person |
      | animal |
    Then entity(woman) get supertypes contain:
      | woman  |
      | person |
      | animal |
    Then entity(person) get supertypes contain:
      | person |
      | animal |
    Then entity(cat) get supertypes contain:
      | cat    |
      | animal |
    Then entity(man) get subtypes contain:
      | man |
    Then entity(woman) get subtypes contain:
      | woman |
    Then entity(person) get subtypes contain:
      | person |
      | man    |
      | woman  |
    Then entity(cat) get subtypes contain:
      | cat |
    Then entity(animal) get subtypes contain:
      | animal |
      | cat    |
      | person |
      | man    |
      | woman  |
