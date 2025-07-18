defmodule Servy.Handler do
  require Logger

  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> track
    |> emojifi
    |> format_response
  end

  def emojifi(%{status: 200} = conv) do
    emojies = String.duplicate("🎉", 5)
    body = emojies <> "\n" <> conv.response_body <> "\n" <> emojies

    %{conv | response_body: body}
  end

  def emojifi(conv), do: conv

  def track(%{status: 404, path: path} = conv) do
    # Logger.info "It's lunchtime somewhere."
    Logger.warning("Warning: #{path} is on the loose!", conv)
    # Logger.error "Danger Will Robinson!"

    # IO.puts("Warning: #{path} is on the loose!")
    conv
  end

  def track(conv), do: conv

  def rewrite_path(%{method: "GET", path: "/wildlife"} = conv) do
    %{conv | path: "/wildthings"}
  end

  # def rewrite_path(%{path: "/bears?id=" <> id} = conv) do
  #   %{conv | path: "/bears/#{id}"}
  # end

  def rewrite_path(%{path: path} = conv) do
    regex = ~r{\/(?<thing>\w+)\?id=(?<id>\d+)}
    captures = Regex.named_captures(regex, path)
    rewrite_path_captures(conv, captures)
  end

  def rewrite_path_captures(conv, %{"thing" => thing, "id" => id}) do
    %{conv | path: "/#{thing}/#{id}"}
  end

  def rewrite_path_captures(conv, nil), do: conv

  def log(conv), do: IO.inspect(conv, label: "Log")

  def parse(request) do
    [method, path, _] =
      request
      |> String.split("\n")
      |> List.first()
      |> String.split(" ")

    %{method: method, path: path, response_body: "", status: nil}
  end

  def route(%{method: "GET", path: "/wildthings"} = conv) do
    %{conv | status: 200, response_body: "Bears, Liöns, Tigers"}
  end

  def route(%{method: "GET", path: "/bears"} = conv) do
    %{conv | status: 200, response_body: "Teddy, Smokey, Paddington"}
  end

  def route(%{method: "GET", path: "/bears/new"} = conv) do
    Path.expand("../../pages", __DIR__)
    |> Path.join("form.html")
    |> File.read()
    |> handle_file(conv)
  end

  # # this is a generic function which captures the filename
  def route(%{method: "GET", path: "/bears/" <> file} = conv) do
    Path.expand("../../pages", __DIR__)
    |> Path.join(file <> ".html")
    |> File.read()
    |> handle_file(conv)
  end

  def route(%{method: "GET", path: "/bears" <> id} = conv) do
    %{conv | status: 200, response_body: "Bear #{id}"}
  end

  def route(%{method: "DELETE", path: "/bears/" <> _id} = conv) do
    %{conv | status: 403, response_body: "Deleting a bear is forbidden!"}
  end

  #   # Using a case expression:

  # def route(%{method: "GET", path: "/bears/new"} = conv) do
  #   pages_path = Path.expand("../../pages", __DIR__)
  #   file = Path.join(pages_path, "form.html")

  #   case File.read(file) do
  #     {:ok, content} ->
  #       %{ conv | status: 200, resp_body: content }

  #     {:error, :enoent} ->
  #       %{ conv | status: 404, resp_body: "File not found!"}

  #     {:error, reason } ->
  #       %{ conv | status: 500, resp_body: "File error: #{reason}"}
  #   end
  # end

  #   # Using a function clauses:

  # # this is a generic function which captures the filename
  # def route(%{method: "GET", path: "/bears/" <> file} = conv) do
  #   Path.expand("../../pages", __DIR__)
  #   |> Path.join(file <> ".html")
  #   |> File.read()
  #   |> handle_file(conv)
  # end

  def route(%{path: path} = conv) do
    %{conv | status: 404, response_body: "NO  #{path} here!"}
  end

  def handle_file({:ok, content}, conv) do
    %{conv | status: 200, response_body: content}
  end

  def handle_file({:error, :enoent}, conv) do
    %{conv | status: 404, response_body: "File not found!"}
  end

  def handle_file({:error, reason}, conv) do
    %{conv | status: 500, response_body: "File error: #{reason}"}
  end

  def format_response(conv) do
    """
    HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
    Content-Type: text/html
    Content-Length: #{byte_size(conv.response_body)}

    #{conv.response_body}
    """
  end

  defp status_reason(code) do
    %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end
end

request = """
GET /wildthings HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts(response)

request = """
GET /bears HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts(response)

request = """
GET /bears?id=1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts(response)

request = """
GET /wildlife HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts(response)

request = """
DELETE /bears/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts(response)

request = """
GET /bigfoot HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts(response)

request = """
GET /bears/new HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle(request)

IO.puts(response)
