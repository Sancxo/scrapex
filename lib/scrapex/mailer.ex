defmodule Scrapex.Mailer do
  use Swoosh.Mailer, otp_app: :scrapex

  import Swoosh.Email

  @typedoc """
  The type of data sent by the email (html or plain text)
  """
  @type mail_type() :: :html | :text

  @recipient Application.compile_env(:scrapex, :recipient)
  @sender_mail Application.compile_env(:scrapex, :sender_mail)

  @doc """
  Build an email form the data (html or text) the Spider crawled
  """
  @spec build_mail(String.t(), binary(), mail_type()) :: any
  def build_mail(spider_name, html_data, :html) do
    spider_name = spider_name |> String.trim_leading("Scrapex.JobSpiders.")

    new()
    |> to({@recipient.name, @recipient.mail})
    |> from({spider_name, @sender_mail})
    |> subject("#{spider_name} - New spider job report")
    |> html_body(html_data)
  end
end
