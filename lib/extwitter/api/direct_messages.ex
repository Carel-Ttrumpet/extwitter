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

  def new_direct_message_with_quick_replies(twitter_id, text, content_type, media_url, quick_replies \\ []) do


    message_body = generate_message_body(twitter_id, text)
                    |> add_quick_replies(quick_replies)
                    |> add_media(media_url, content_type)
                    |> Poison.encode!
    request_with_body(:post, "1.1/direct_messages/events/new.json", message_body)
  end

  def get_image(partial_url) do
    ton_request(:get, partial_url)
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

  def download_media(media_url) do
    Logger.warn "Media url in direct messages: #{inspect media_url}"
    %HTTPoison.Response{body: body} = HTTPoison.get!(media_url)
    path = "/tmp/" <> random_string(8)
    File.write!(path, body)
    path
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

  def add_media(message, media_url, content_type) do
    if media_url != "" do
      path = download_media(media_url)
      media_id = upload_media(media_url, path, content_type)
      File.rm path
      message = put_in(message, ["event", "message_create", "message_data", "attachment"], attachment_map(media_id))
    end
    message
  end

  def attachment_map(media_id) do
    %{
        "type" => "media",
        "media" => %{
          "id" => media_id
        }
    }
  end

  def add_quick_replies(message, quick_replies) do
    if length(quick_replies) > 0 do
      message = put_in(message, ["event", "message_create", "message_data", "quick_reply"], quick_reply_map(quick_replies))
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


