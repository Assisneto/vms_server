defmodule VmsServer.Repo.Migrations.CreateChronicleTable do
  use Ecto.Migration

  def change do
    create table(:chronicle, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :storyteller_id, references(:user, type: :uuid), null: false

      timestamps()
    end
  end
end
