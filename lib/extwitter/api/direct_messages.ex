defmodule ExTwitter.API.DirectMessages do
  @moduledoc """
  Provides Direct Messages API interfaces.
  """
  require Logger
  import ExTwitter.API.Base

  def direct_message(id) do
    request(:get, "1.1/direct_messages/show/#{id}.json")
    |> ExTwitter.Parser.parse_direct_message
  end

  def direct_messages(options \\ []) do
    params = ExTwitter.Parser.parse_request_params(options)
    request(:get, "1.1/direct_messages.json", params)
    |> Enum.map(&ExTwitter.Parser.parse_direct_message/1)
  end

  def sent_direct_messages(options \\ []) do
    params = ExTwitter.Parser.parse_request_params(options)
    request(:get, "1.1/direct_messages/sent.json", params)
    |> Enum.map(&ExTwitter.Parser.parse_direct_message/1)
  end

  def destroy_direct_message(id, options \\ []) do
    params = ExTwitter.Parser.parse_request_params(options)
    request(:post, "1.1/direct_messages/destroy/#{id}.json", params)
    |> ExTwitter.Parser.parse_direct_message
  end

  # Additional options in the form of a keyword list can be added.
  # e.g [quick_reply: %{"type" => "options", "options" => [%{"label" => "Red bird", "description" => "Red bird description", "metadata" => "ext_id_1"}] }]
  def new_direct_message(id_or_screen_name, text, additional_options \\ []) do
    params = ExTwitter.Parser.parse_request_params(get_id_option(id_or_screen_name) ++ [text: text] ++ additional_options)
    IO.inspect params
    request(:post, "1.1/direct_messages/new.json", params)
    |> ExTwitter.Parser.parse_direct_message
  end

  def new_direct_message_with_quick_replies(twitter_id, text, quick_replies \\ []) do
    message_body = generate_message_body(twitter_id, text)
                    |> add_quick_replies(quick_replies)
                    |> Poison.encode!
    Logger.warn "Posting message body: #{inspect message_body}"
    request_with_body(:post, "1.1/direct_messages/events/new.json", message_body)
    |> ExTwitter.Parser.parse_direct_message
  end

  def generate_message_body(twitter_id, text) do
    %{
      "event" => %{
        "type" => "message_create",
        "message_create" => %{
          "target" => %{
            "recipient_id" => twitter_id
          },
          "message_data" => %{
            "text" => text
          }
        }
      }
    }
  end

  def add_quick_replies(message, quick_replies) do
    if length(quick_replies) > 0 do
      message = put_in(message, ["event", "message_data", "quick_reply"], quick_reply_map(quick_replies))
    end
    message
  end

  def quick_reply_map(quick_replies) do
    %{
        "type" => "options",
        "options" => Enum.map(quick_replies, fn(reply) -> %{"label" => reply, "metadata" => reply} end)
      }
  end
end


