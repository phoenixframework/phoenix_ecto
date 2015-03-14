defmodule PhoenixEctoTest do
  use ExUnit.Case, async: true

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :name
    end
  end

  import Phoenix.HTML
  import Phoenix.HTML.Form

  test "converts decimal to safe" do
    assert html_escape(Decimal.new("1.0")) == {:safe, "1.0"}
  end

  test "converts time to safe" do
    t = %Ecto.Time{hour: 0, min: 0, sec: 0}
    assert html_escape(t) == {:safe, "00:00:00"}
  end

  test "form_for/4 with new changeset" do
    changeset = Ecto.Changeset.cast(%User{}, nil, ~w(), ~w())

    {:safe, form} = form_for(changeset, "/", fn f ->
      assert f.name == "user"
      assert f.source == changeset
      assert f.params == %{}
      assert f.hidden == []
      ""
    end)

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" method="post">)
  end

  test "form_for/4 with loaded changeset" do
    changeset = Ecto.Changeset.cast(%User{__state__: :loaded, id: 13},
                                    %{"foo" => "bar"}, ~w(), ~w())

    {:safe, form} = form_for(changeset, "/", fn f ->
      assert f.name == "user"
      assert f.source == changeset
      assert f.params == %{"foo" => "bar"}
      assert f.hidden == [id: 13]
      ""
    end)

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" method="post">)
    assert form =~ ~s(<input name="_method" type="hidden" value="put">)
    refute form =~ ~s(<input id="user_id" name="user[id]" type="hidden" value="13">)
  end

  test "form_for/4 with custom options" do
    changeset = Ecto.Changeset.cast(%User{}, nil, ~w(), ~w())

    {:safe, form} = form_for(changeset, "/", [name: "another", multipart: true], fn f ->
      assert f.name == "another"
      assert f.source == changeset
      ""
    end)

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">)
  end
end
