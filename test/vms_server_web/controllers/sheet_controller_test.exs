defmodule VmsServerWeb.SheetControllerTest do
  alias VmsServer.Repo
  use VmsServerWeb.ConnCase

  import VmsServer.Factory

  describe "get_characteristics_fields/2" do
    setup %{conn: conn} do
      race = insert(:race, name: "vampire")
      category = insert(:category_with_race, %{race_id: race.id})
      insert(:characteristics, %{category_id: category.id, name: "strength"})
      insert(:dynamic_characteristics, %{category_id: category.id, name: "willpower"})

      {:ok, %{conn: conn, race: race}}
    end

    test "returns 200 OK with characteristics fields for a known race id", %{
      conn: conn,
      race: race
    } do
      conn = get(conn, ~p"/api/sheet/characteristics/#{race.id}")
      assert json_response(conn, 200) != []
    end

    test "returns 204 No Content for an unknown race id", %{conn: conn} do
      unknown_race_id = "00000000-0000-0000-0000-000000000000"
      conn = get(conn, ~p"/api/sheet/characteristics/#{unknown_race_id}")
      assert response(conn, 204)
    end
  end

  describe "create/2" do
    setup %{conn: conn} do
      race = insert(:race, name: "vampire")
      player = insert(:player)
      chronicle = insert(:chronicle)
      category = insert(:category_with_race, %{race_id: race.id})

      characteristics =
        Enum.map(1..5, fn _ -> insert(:characteristics, %{category_id: category.id}) end)

      dynamic_characteristics =
        Enum.map(1..2, fn _ -> insert(:dynamic_characteristics, %{category_id: category.id}) end)

      characteristics_levels =
        Enum.map(characteristics, fn char ->
          %{characteristic_id: char.id, level: Enum.random(1..5)}
        end)

      dynamic_characteristics_levels =
        Enum.map(dynamic_characteristics, fn char ->
          %{characteristic_id: char.id, level: Enum.random(1..5), used: Enum.random(0..2)}
        end)

      attrs = %{
        name: "Benimary",
        race_id: race.id,
        player_id: player.id,
        chronicle_id: chronicle.id,
        characteristics_levels: characteristics_levels,
        dynamic_characteristics_levels: dynamic_characteristics_levels,
        character_specific_characteristics: [],
        race_characteristics: [%{key: "Agility", value: "High"}],
        bashing: 0,
        lethal: 0,
        aggravated: 0
      }

      {:ok, %{conn: conn, attrs: attrs}}
    end

    test "creates a character and returns 201 Created", %{conn: conn, attrs: attrs} do
      conn = post(conn, "/api/sheet", attrs)
      character_id = json_response(conn, 201)["id"]
      assert character_id != nil
      assert Repo.get_by(VmsServer.Sheet.Character, id: character_id) != nil
    end

    test "fails to create a character when race_id, player_id, or chronicle_id are blank", %{
      conn: conn,
      attrs: attrs
    } do
      attrs_without_required_ids = Map.drop(attrs, [:race_id, :player_id, :chronicle_id])
      response = post(conn, "/api/sheet", attrs_without_required_ids)
      assert json_response(response, 400)["errors"]["race_id"] == ["can't be blank"]

      assert json_response(response, 400)["errors"]["player_id"] == [
               "can't be blank"
             ]

      assert json_response(response, 400)["errors"]["chronicle_id"] == [
               "can't be blank"
             ]
    end

    test "fails to create a character when characteristic_id does not exist", %{
      conn: conn,
      attrs: attrs
    } do
      non_existent_characteristic_id = "00000000-0000-0000-0000-000000000000"

      attrs_with_non_existent_characteristic_id =
        Map.put(attrs, :characteristics_levels, [
          %{characteristic_id: non_existent_characteristic_id, level: 3}
        ])

      response = post(conn, "/api/sheet", attrs_with_non_existent_characteristic_id)

      assert json_response(response, 400)["errors"]["characteristics_levels"] != nil

      assert Enum.any?(
               json_response(response, 400)["errors"]["characteristics_levels"],
               fn error ->
                 Enum.any?(error["characteristic_id"], fn msg -> msg == "does not exist" end)
               end
             )
    end

    test "fails to create a character when dynamic_characteristic_id does not exist", %{
      conn: conn,
      attrs: attrs
    } do
      non_existent_dynamic_characteristic_id = "00000000-0000-0000-0000-000000000000"

      attrs_with_non_existent_dynamic_characteristic_id =
        Map.put(attrs, :dynamic_characteristics_levels, [
          %{characteristic_id: non_existent_dynamic_characteristic_id, level: 3, used: 1}
        ])

      response =
        post(conn, "/api/sheet", attrs_with_non_existent_dynamic_characteristic_id)

      assert json_response(response, 400)["errors"]["dynamic_characteristics_levels"] != nil

      assert Enum.any?(
               json_response(response, 400)["errors"]["dynamic_characteristics_levels"],
               fn error ->
                 Enum.any?(error["characteristic_id"], fn msg -> msg == "does not exist" end)
               end
             )
    end

    test "fails to create a character when level and used are blank in dynamic_characteristics_levels",
         %{
           conn: conn,
           attrs: attrs
         } do
      category = insert(:category)
      dynamic_characteristic = insert(:dynamic_characteristics, %{category_id: category.id})

      attrs_with_blank_level_and_used =
        Map.put(attrs, :dynamic_characteristics_levels, [
          %{characteristic_id: dynamic_characteristic.id, level: nil, used: nil}
        ])

      response = post(conn, "/api/sheet", attrs_with_blank_level_and_used)

      errors = json_response(response, 400)["errors"]["dynamic_characteristics_levels"]

      assert errors != nil

      assert Enum.any?(errors, fn error ->
               error["used"] == ["can't be blank"] and error["level"] == ["can't be blank"]
             end)
    end

    test "fails to create a character when characteristic name is missing in characteristics", %{
      conn: conn,
      attrs: attrs
    } do
      category = insert(:category)

      attrs_with_missing_name_in_characteristics =
        Map.put(attrs, :characteristics, [
          %{
            "category_id" => category.id,
            "characteristics_levels" => %{
              "level" => 3
            }
          }
        ])

      response = post(conn, "/api/sheet", attrs_with_missing_name_in_characteristics)

      errors = json_response(response, 400)["errors"]["characteristics"]

      assert Enum.any?(errors, fn error -> Enum.any?(error, fn {key, _} -> key == "name" end) end)
    end

    test "fails to create a character when category_id does not exist in characteristics", %{
      conn: conn,
      attrs: attrs
    } do
      non_existent_category_id = "00000000-0000-0000-0000-000000000000"

      attrs_with_non_existent_category_id_in_characteristics =
        Map.put(attrs, :characteristics, [
          %{
            "name" => "Fortitude",
            "characteristics_levels" => %{
              "level" => 3
            },
            "category_id" => non_existent_category_id
          }
        ])

      response = post(conn, "/api/sheet", attrs_with_non_existent_category_id_in_characteristics)

      errors = json_response(response, 400)["errors"]["characteristics"]

      assert errors != nil

      assert Enum.any?(errors, fn error ->
               Enum.any?(error["category_id"], fn msg -> msg == "does not exist" end)
             end)
    end

    test "fails to create a character when category_id is blank in characteristics", %{
      conn: conn,
      attrs: attrs
    } do
      attrs_with_blank_category_id_in_characteristics =
        Map.put(attrs, :characteristics, [
          %{
            "name" => "Fortitude",
            "characteristics_levels" => %{
              "level" => 3
            },
            "category_id" => ""
          }
        ])

      response = post(conn, "/api/sheet", attrs_with_blank_category_id_in_characteristics)

      errors = json_response(response, 400)["errors"]["characteristics"]

      assert errors != nil

      assert Enum.any?(errors, fn error ->
               Enum.any?(error["category_id"], fn msg -> msg == "can't be blank" end)
             end)
    end

    test "fails to create a character when key is blank in race_characteristics", %{
      conn: conn,
      attrs: attrs
    } do
      attrs_with_blank_key_in_race_characteristics =
        Map.put(attrs, :race_characteristics, [
          %{"key" => "", "value" => "High"}
        ])

      response = post(conn, "/api/sheet", attrs_with_blank_key_in_race_characteristics)

      errors = json_response(response, 400)["errors"]["race_characteristics"]

      assert errors != nil

      assert Enum.any?(errors, fn error ->
               Enum.any?(error["key"], fn msg -> msg == "can't be blank" end)
             end)
    end
  end
end
