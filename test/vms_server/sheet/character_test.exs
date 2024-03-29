defmodule VmsServer.Sheet.CharacterTest do
  use ExUnit.Case, async: true
  use VmsServer.DataCase

  alias VmsServer.Sheet.Character
  import VmsServer.Factory

  describe "create_changeset/2" do
    test "validates presence of required fields" do
      attrs = %{}
      changeset = Character.create_changeset(%Character{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).race_id
      assert "can't be blank" in errors_on(changeset).user_id
      assert "can't be blank" in errors_on(changeset).chronicle_id
    end

    test "creates a character with valid data" do
      race = insert(:race)
      user = insert(:user)
      chronicle = insert(:chronicle)

      attrs = %{
        name: "Aragorn",
        race_id: race.id,
        user_id: user.id,
        chronicle_id: chronicle.id,
        bashing: 5,
        lethal: 3,
        aggravated: 1
      }

      changeset = Character.create_changeset(%Character{}, attrs)
      assert changeset.valid?
      {:ok, character} = Repo.insert(changeset)

      assert character.name == attrs.name
      assert character.bashing == attrs.bashing
      assert character.lethal == attrs.lethal
      assert character.aggravated == attrs.aggravated
    end

    test "creates a character with characteristics levels, dynamic characteristics levels, and race characteristics inside of character changeset" do
      race = insert(:race)
      user = insert(:user)
      chronicle = insert(:chronicle)
      characteristic = insert(:characteristics)
      dynamic_characteristic = insert(:dynamic_characteristics)
      race_characteristic_attrs = %{key: "Agility", value: "High"}

      attrs = %{
        name: "Aragorn",
        race_id: race.id,
        user_id: user.id,
        chronicle_id: chronicle.id,
        bashing: 5,
        lethal: 3,
        aggravated: 1,
        characteristics_levels: [
          %{
            characteristic_id: characteristic.id,
            level: 5
          }
        ],
        dynamic_characteristics_levels: [
          %{
            characteristic_id: dynamic_characteristic.id,
            level: 4,
            used: 2
          }
        ],
        race_characteristics: [race_characteristic_attrs]
      }

      changeset = Character.create_changeset(%Character{}, attrs)
      assert changeset.valid?
      {:ok, character} = Repo.insert(changeset)

      assert length(character.characteristics_levels) == 1
      assert Enum.all?(character.characteristics_levels, fn cl -> cl.level == 5 end)
      assert length(character.dynamic_characteristics_levels) == 1

      assert Enum.all?(character.dynamic_characteristics_levels, fn dcl ->
               dcl.level == 4 and dcl.used == 2
             end)

      assert length(character.race_characteristics) == 1

      assert List.first(character.race_characteristics).key == "Agility"
      assert List.first(character.race_characteristics).value == "High"
    end

    test "updates a character's stats" do
      character = insert(:character, name: "Legolas", bashing: 0)

      updated_attrs = %{name: "Legolas Greenleaf", bashing: 2}
      changeset = Character.update_changeset(character, updated_attrs)
      {:ok, updated_character} = Repo.update(changeset)

      assert updated_character.name == updated_attrs.name
      assert updated_character.bashing == updated_attrs.bashing
    end
  end

  describe "update_changeset/2" do
    test "updates a character with new lethal damage value" do
      character = insert(:character, name: "Gimli", lethal: 2)

      updated_attrs = %{lethal: 5}
      changeset = Character.update_changeset(character, updated_attrs)
      {:ok, updated_character} = Repo.update(changeset)

      assert updated_character.lethal == updated_attrs.lethal
    end
  end
end
