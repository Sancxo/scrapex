defmodule Scrapex.HashRegistry do
  @moduledoc "Genserver used to manage cache into an ETS table called :hash_registry."
  require Logger
  use GenServer

  @table :hash_registry

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{})

  @doc "Stores the hash in ETS using Spider as key."
  @spec upsert(String.t(), binary()) :: true
  def upsert(spider, new_hash), do: :ets.insert(@table, {spider, new_hash})

  @doc "Returns the hash stored in ETS for this Spider."
  @spec lookup(String.t()) :: binary() | nil
  def lookup(spider) do
    :ets.lookup(@table, spider)
    |> case do
      [] ->
        Logger.info("Nothing in table, return nil")
        nil

      [{_spider, previous_hash}] ->
        Logger.info("Data found, returning #{previous_hash}")
        previous_hash
    end
  end

  @impl true
  @spec init(any()) :: {:ok, any()}
  def init(state \\ []) do
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, state}
  end
end
