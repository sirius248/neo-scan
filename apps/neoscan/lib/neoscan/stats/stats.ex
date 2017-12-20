defmodule Neoscan.Stats do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Neoscan.Stats.Counter
  alias Neoscan.Repo
  alias Neoscan.Blocks
  alias Neoscan.Transactions
  alias Neoscan.Addresses
  alias Neoscan.ChainAssets

  require Logger

  @doc """
  Creates an stats.

  ## Examples

      iex> create_stats(%{field: value})
      {:ok, %stats{}}

      iex> create_stats(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def initialize_counter() do
    %{
      :total_blocks => Blocks.count_blocks(),
      :total_transactions=> Transactions.count_transactions(),
      :total_addresses => Addresses.count_addresses(),
      :contract_transactions => Transactions.count_transactions(['ContractTransaction']),
      :invocation_transactions => Transactions.count_transactions(['InvocationTransaction']),
      :miner_transactions => Transactions.count_transactions(['MinerTransaction']),
      :publish_transactions => Transactions.count_transactions(['PublishTransaction']),
      :issue_transactions => Transactions.count_transactions(['IssueTransaction']),
      :register_transactions => Transactions.count_transactions(['RegisterTransaction']),
    }
    |> Map.merge(ChainAssets.get_assets_stats())
    |> Counter.changeset()
    |> Repo.insert!()
  end


  @doc """
  Updates an stats.

  ## Examples

      iex> update_stats(stats, %{field: new_value})
      {:ok, %stats{}}

      iex> update_stats(stats, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_counter(%Counter{} = counter, attrs) do
    counter
    |> Counter.update_changeset(attrs)
    |> Repo.update!()
  end

  def get_counter do
    Repo.all(Counter)
    |> List.first()
    |> create_if_doesnt_exists()
  end

  def create_if_doesnt_exists(nil) do
    initialize_counter()
  end
  def create_if_doesnt_exists(counter) do
    counter
  end

  def add_block_to_table() do
    counter = get_counter()
    attrs = %{:total_blocks => Map.get(counter, :total_blocks) + 1}
    update_counter(counter, attrs)
  end

  def add_transaction_to_table(transaction) do
    counter = get_counter()
    attrs = case Map.get(transaction, :type) do
      "ContractTransaction" ->
        %{
          :total_transactions => Map.get(counter, :total_transactions) + 1,
          :contract_transactions => Map.get(counter, :contract_transactions) + 1,
        }
      "InvocationTransaction" ->
        %{
           :total_transactions => Map.get(counter, :total_transactions) + 1,
           :invocation_transactions => Map.get(counter, :invocation_transactions) + 1,
         }
      "ClaimTransaction" ->
        %{
           :total_transactions => Map.get(counter, :total_transactions) + 1,
           :claim_transactions => Map.get(counter, :claim_transactions) + 1,
         }
      "PublishTransaction" ->
        %{
           :total_transactions => Map.get(counter, :total_transactions) + 1,
           :publish_transactions => Map.get(counter, :publish_transactions) + 1,
         }
      "RegisterTransaction" ->
        %{
           :total_transactions => Map.get(counter, :total_transactions) + 1,
           :register_transactions => Map.get(counter, :register_transactions) + 1,
         }
      "IssueTransaction" ->
        %{
           :total_transactions => Map.get(counter, :total_transactions) + 1,
           :issue_transactions => Map.get(counter, :issue_transactions) + 1,
         }
      "MinerTransaction" ->
        %{
           :miner_transactions => Map.get(counter, :miner_transactions) + 1,
         }
    end

    attrs = case Map.get(transaction, :asset_moved) do
      nil ->
        attrs
      asset ->
        new_map = Map.get(counter, :asset_transactions)
                  |> Map.get_and_update(asset, fn n ->
                    case n do
                      nil ->
                        1
                      n ->
                        n + 1
                    end
                  end)

        Map.put(attrs, :asset_transactions, new_map)
    end

    update_counter(counter, attrs)
  end

end
