defmodule VmsServer.Factory do
  alias VmsServer.Sheet.{Player, Race, Character, Chronicle}
  use ExMachina.Ecto, repo: VmsServer.Repo

  def player_factory do
    %Player{
      name: "Assis neto"
    }
  end

  def race_factory do
    %Race{
      name: "Vampire",
      description: "Elegant and wise"
    }
  end

  def chronicle_factory do
    %Player{id: storyteller_id} = insert(:player)

    %Chronicle{
      title: "Rise and fall of noob saibot",
      description: "Demon noob saibot",
      storyteller_id: storyteller_id
    }
  end

  def character_factory do
    %Player{id: player_id} = insert(:player)
    %Race{id: race_id} = insert(:race)
    %Chronicle{id: chronicle_id} = insert(:chronicle)

    %Character{
      name: "Marcos Capella",
      bashing: 0,
      lethal: 0,
      aggravated: 0,
      race_id: race_id,
      player_id: player_id,
      chronicle_id: chronicle_id
    }
  end
end