defmodule Mockable do
  def set_mock(mock, for: mocked) do
    Application.put_env(__MODULE__, mocked, mock)
  end

  def get_mock(mocked) do
    Application.get_env(__MODULE__, mocked, original_module_name(mocked))
  end

  def delete_mock(mocked) do
    Application.delete_env(__MODULE__, mocked)
  end

  defmacro __using__(_opts) do
    quote do
      if Code.ensure_loaded?(Mix) && Mix.env() == :test do
        Module.register_attribute(__MODULE__, :function_parts, accumulate: true)
        @before_compile unquote(__MODULE__)
        @after_compile unquote(__MODULE__)
        @on_definition unquote(__MODULE__)
      end
    end
  end

  def __on_definition__(env, _kind, name, args, guards, body) do
    Module.put_attribute(env.module, :function_parts, {name, args, guards, body})
  end

  defmacro __before_compile__(env) do
    specs =
      env.module
      |> Module.get_attribute(:spec)
      |> Enum.map(fn {:spec, spec, _} ->
        quote do
          @spec unquote(spec)
        end
      end)

    env.module
    |> Module.definitions_in()
    |> Enum.map(&Module.spec_to_callback(env.module, &1))

    Module.make_overridable(env.module, Module.definitions_in(env.module))

    quoted_original_functions =
      env.module
      |> Module.get_attribute(:function_parts)
      |> Enum.reverse()
      |> Enum.map(fn {name, args, guards, body} ->
        quoted_function(name, args, guards, body, true)
      end)

    quoted_proxy_functions =
      env.module
      |> Module.get_attribute(:function_parts)
      |> Enum.reverse()
      |> Enum.group_by(fn {name, args, _, _} -> {name, length(args)} end)
      |> Map.values()
      |> Enum.map(&List.first/1)
      |> Enum.map(fn {name, args, guards, _body} ->
        proxy_body = quoted_proxy_body(name, args)

        quoted_function(name, args, guards, proxy_body)
      end)

    quoted_original_module_body =
      quote do
        @behaviour unquote(env.module)
        unquote_splicing(quoted_original_functions)
      end

    Module.put_attribute(env.module, :mockable_original_body, quoted_original_module_body)

    quote do
      unquote_splicing(specs)

      unquote_splicing(quoted_proxy_functions)
    end
  end

  def __after_compile__(env, _bytecode) do
    quoted_original_module_body =
      env.module
      |> Module.get_attribute(:mockable_original_body)
      |> Macro.update_meta(&Keyword.put(&1, :context, env.module))

    Module.delete_attribute(env.module, :mockable_original_body)

    env.module
    |> original_module_name
    |> Module.create(quoted_original_module_body, Macro.Env.location(__ENV__))
  end

  defp original_module_name(module) do
    __MODULE__
    |> Module.concat(module)
    |> Module.concat("Original")
  end

  defp quoted_proxy_body(name, args) do
    defaults_stripped_args =
      Enum.map(args, fn
        {:\\, _, [arg, _default]} ->
          arg

        arg ->
          arg
      end)

    body =
      quote do
        mock = unquote(__MODULE__).get_mock(__MODULE__)
        args = [unquote_splicing(defaults_stripped_args)]

        :erlang.apply(mock, unquote(name), args)
      end

    [do: body]
  end

  defp quoted_function(name, args, guards, body, impl? \\ false) do
    impl =
      quote do
        if unquote(impl?) do
          @impl true
        end
      end

    if length(guards) > 0 do
      quote do
        unquote(impl)
        def unquote(name)(unquote_splicing(args)) when unquote_splicing(guards), unquote(body)
      end
    else
      quote do
        unquote(impl)
        def unquote(name)(unquote_splicing(args)), unquote(body)
      end
    end
  end
end
