defmodule Conduit.Accounts.Aggregates.User do
  defstruct [
    :uuid,
    :username,
    :email,
    :hashed_password,
  ]

  alias Conduit.Accounts.Aggregates.User

  @doc """
  Register a new user
  """
  def execute(%User{uuid: nil}, %RegisterUser{} = register) do
    %UserRegistered{
      uuid: register.uuid,
      username: register.username,
      email: register.email,
      hashed_password: register.hashed_password,
    }
  end

  # state mutators

  def apply(%User{} = user, %UserRegistered{} = registered) do
    %User{user |
      uuid: registered.uuid,
      username: registered.username,
      email: registered.email,
      hashed_password: registered.hashed_password,
    }
  end
end
