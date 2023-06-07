#defmodule MainWeb.WhatsappController do
#  use MainWeb, :controller
#  alias Data.Conversations, as: C
#  alias Data.ConversationMessages, as: CM
#  alias Data.Schema.Conversation, as: Schema
#  alias Main.Service.Appointment
#  alias Data.Team
#
#  alias MainWeb.{Notify}
#
#  alias Data.{Member, TimezoneOffset, TeamMember, Conversations}
#
#  alias Data.{Location, Team}
#
#
##  def login(conn, %{new_password: new_password, credentials: credentials // "YWRtaW46c2VjcmV0"} = params) do
##    IO.inspect("=======================params=====================")
##    IO.inspect(params)
##    IO.inspect("=======================params=====================")
##    if (Regex.match?(~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*])(?=.{8,})/, new_password)) do
##    encoded_credentials = Base.encode64(credentials)
##    url = "https://localhost:9090/v1/users/login"
##    headers = [{"Content-Type", "application/json", "Authorization", "Basic YWRtaW46c2VjcmV0"}]
##    body = %{new_password: "znkEbc4t@s@BJ7t"} |> Jason.encode!
##    case HTTPoison.post(url, body, headers)do
##      {:ok, res} -> Poison.decode!(res.body)
##      error -> :error
##    end
##    else
##      {:error, ["should contain at least one upper case, lower case, digit, special character and must be at least 8 characters in length."]}
##    end
##  end
##  def login(conn, %{"credentials" => credentials} = params) do
##    encoded_credentials = Base.encode64(credentials)
##    url = "https://localhost:9090/v1/users/login"
##    headers = [{"Content-Type", "application/json", "Authorization", "Basic YWRtaW46c2VjcmV0"}]
##    body = %{new_password: "znkEbc4t@s@BJ7t"} |> Jason.encode!
##    case HTTPoison.post(url, body, headers)do
##      {:ok, res} -> Poison.decode!(res.body)
##      error -> :error
##    end
##    else
##      {:error, ["should contain at least one upper case, lower case, digit, special character and must be at least 8 characters in length."]}
##  end
#
##  def event(conn, %{"location_id" => location_id} = params) do
##    location = Location.get(location_id)
##    with %Schema{} = convo <- C.get_by_phone("instagram:#{u_id}", location.id) do
###      get_user_details(location, sid)
##      update_convo(msg,convo,location)
##    else
##      nil ->
##        with {:ok, %Schema{} = convo} <- C.find_or_start_conversation({"messenger:#{u_id}", location.phone_number}) do
###          get_user_details(location,sid)
##            close_conversation(convo.id, location)
##          update_convo(msg,convo,location)
##        end
##    end
##    conn
##    |> Plug.Conn.resp(200, "")
##    |> Plug.Conn.send_resp()
##  end
##  def update_convo(message,convo,location)do
##    {:ok, struct} = CM.create(
##      %{
##        "conversation_id" => convo.id,
##        "phone_number" => convo.original_number,
##        "message" => message,
##        "sent_at" => DateTime.utc_now()
##      })
##    if convo.status == "closed" do
##      message
##      |> ask_wit_ai(convo.id, location)
##      |> case do
##           {:ok, response} ->
##              CM.create(
##               %{
##                 "conversation_id" => convo.id,
##                 "phone_number" => location.phone_number,
##                 "message" => response,
##                 "sent_at" => DateTime.add(DateTime.utc_now(), 2)
##               }
##             )
##             reply_to_facebook(response,location,String.replace(convo.original_number,"messenger:",""))
##             Main.LiveUpdates.notify_live_view({convo.id, struct})
##             close_conversation(convo.id, location)
##           {:unknown, response} ->
##             CM.create(
##               %{
##                 "conversation_id" => convo.id,
##                 "phone_number" => location.phone_number,
##                 "message" => response,
##                 "sent_at" => DateTime.add(DateTime.utc_now(), 2)
##               }
##             )
##             reply_to_facebook(response,location,String.replace(convo.original_number,"messenger:",""))
##             C.pending(convo.id)
##             Main.LiveUpdates.notify_live_view({location.id, :updated_open})
##             Main.LiveUpdates.notify_live_view({convo.id, struct})
##             MainWeb.Endpoint.broadcast("alert:#{location.phone_number}", "broadcast", %{location: location, convo: convo.id})
##             :ok =
##               Notify.send_to_admin(
##                 convo.id,
##                 message,
##                 location.phone_number,
##                 "location-admin"
##               )
##         end
##         else
##      Main.LiveUpdates.notify_live_view({convo.id, struct})
##      MainWeb.Endpoint.broadcast("alert:#{location.phone_number}", "broadcast", %{location: location, convo: convo.id})
##    end
##  end
##
##  defp ask_wit_ai(question, convo_id, location) do
##    bot_id = Team.get_bot_id_by_location_id(location.id)
##    with {:ok, _pid} <- WitClient.MessageSupervisor.ask_question(self(), question, bot_id) do
##      receive do
##        {:response, response} ->
##          message =  Appointment.get_next_reply(convo_id, response, location.phone_number)
##          if String.contains?(message,location.default_message) do
##            {:unknown, message}
##          else
##            {:ok, message}
##          end
##        _ ->
##          {:unknown, location.default_message}
##      end
##    else
##      {:error, _error} ->
##
##        {:unknown, location.default_message}
##    end
##  end
##  defp close_conversation(convo_id, location) do
##
##    disposition =
##      %{role: "system"}
##      |> Data.Disposition.get_by_team_id(location.team_id)
##      |> Enum.find(&(&1.disposition_name == "Automated"))
##
##    if disposition do
##      Data.ConversationDisposition.create(%{"conversation_id" => convo_id, "disposition_id" => disposition.id})
##
##      _ =  %{
##             "conversation_id" => convo_id,
##             "phone_number" => location.phone_number,
##             "message" =>
##               "CLOSED: Closed by System with disposition #{disposition.disposition_name}",
##             "sent_at" => DateTime.add(DateTime.utc_now(), 3)
##           }
##           |> CM.create()
##    else
##      _ = %{
##            "conversation_id" => convo_id,
##            "phone_number" => location.phone_number,
##            "message" =>
##              "CLOSED: Closed by System",
##            "sent_at" => DateTime.add(DateTime.utc_now(), 3)
##          }
##          |> CM.create()
##    end
##
##    C.close(convo_id)
##  end
##  def reply_to_facebook(msg,location,recipient)do
##    url = "https://graph.facebook.com/v11.0/me/messages?access_token=#{location.facebook_token}"
##    body =%{
##            messaging_type: "RESPONSE",
##            recipient: %{
##              id: recipient
##            },
##            message: %{
##              text: msg
##            }} |> Jason.encode!
##    case HTTPoison.post(url,body,[{"Content-Type", "application/json"}])do
##      {:ok, res} -> Poison.decode!(res.body)
##      error ->
##        :error
##    end
##  end
##  def get_user_details(location,recipient)do
##    "https://graph.facebook.com/#{recipient}?fields=first_name,last_name,profile_pic&access_token=#{location.facebook_token}"
##    |> HTTPoison.get()
##    |> case do
##         {:ok, %HTTPoison.Response{status_code: 200,body: body}} ->
##           data = Jason.decode!(body)
##           member =%{
##           "phone_number" => "messenger:#{recipient}",
##           "first_name" => data["first_name"],
##           "last_name" => data["last_name"],
##           "team_id" => location.team_id
##
##           }
##           MainWeb.UpdateMemberController.update(member)
##           :ok
##         error ->
##           {:error, :unauthorized}
##       end
##  end
#end
#
###https://2e83-39-45-196-127.ngrok.io/admin/teams/993ed7d1-f9bc-48de-865e-313b53c7bd47/locations/a7c86ffb-e417-4ff3-9aec-c410a8aee176/hook