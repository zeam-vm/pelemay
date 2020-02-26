defmodule Debug do
  alias Pelemay.Generator
  alias Pelemay.Db
  alias Optimizer

  @table_name :nif_func

  def test1 do
    Db.init()

    def = [
      {:def, [context: Elixir, import: Kernel],
       [
         {:list_mult_2, [context: Elixir], [{:list, [], Elixir}]},
         [
           do:
             {:|>, [context: Elixir, import: Kernel],
              [
                {:|>, [context: Elixir, import: Kernel],
                 [
                   {:|>, [context: Elixir, import: Kernel],
                    [
                      {:list, [], Elixir},
                      {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                       [
                         {:&, [],
                          [
                            {:*, [context: Elixir, import: Kernel], [{:&, [], [1]}, 3]}
                          ]}
                       ]}
                    ]},
                   {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                    [
                      {:&, [], [{:*, [context: Elixir, import: Kernel], [{:&, [], [1]}, 2]}]}
                    ]}
                 ]},
                {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                 [
                   {:&, [], [{:+, [context: Elixir, import: Kernel], [{:&, [], [1]}, 4]}]}
                 ]}
              ]}
         ]
       ]},
      {:def, [context: Elixir, import: Kernel],
       [
         {:list_div_2, [context: Elixir], [{:list, [], Elixir}]},
         [
           do:
             {:|>, [context: Elixir, import: Kernel],
              [
                {:|>, [context: Elixir, import: Kernel],
                 [
                   {:list, [], Elixir},
                   {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                    [
                      {:&, [], [{:/, [context: Elixir, import: Kernel], [{:&, [], [1]}, 2]}]}
                    ]}
                 ]},
                {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                 [
                   {:&, [], [{:+, [context: Elixir, import: Kernel], [{:&, [], [1]}, 4]}]}
                 ]}
              ]}
         ]
       ]},
      {:def, [context: Elixir, import: Kernel],
       [
         {:logistic_map, [context: Elixir], [{:list, [], Elixir}]},
         [
           do:
             {:|>, [context: Elixir, import: Kernel],
              [
                {:|>, [context: Elixir, import: Kernel],
                 [
                   {:|>, [context: Elixir, import: Kernel],
                    [
                      {:list, [], Elixir},
                      {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                       [
                         {:&, [],
                          [
                            {:rem, [context: Elixir, import: Kernel],
                             [
                               {:*, [context: Elixir, import: Kernel],
                                [
                                  {:*, [context: Elixir, import: Kernel], [22, {:&, [], [1]}]},
                                  {:+, [context: Elixir, import: Kernel], [{:&, [], [1]}, 1]}
                                ]},
                               6_700_417
                             ]}
                          ]}
                       ]}
                    ]},
                   {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                    [
                      {:&, [],
                       [
                         {:rem, [context: Elixir, import: Kernel],
                          [
                            {:*, [context: Elixir, import: Kernel],
                             [
                               {:*, [context: Elixir, import: Kernel], [22, {:&, [], [1]}]},
                               {:+, [context: Elixir, import: Kernel], [{:&, [], [1]}, 1]}
                             ]},
                            6_700_417
                          ]}
                       ]}
                    ]}
                 ]},
                {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
                 [
                   {:&, [],
                    [
                      {:rem, [context: Elixir, import: Kernel],
                       [
                         {:*, [context: Elixir, import: Kernel],
                          [
                            {:*, [context: Elixir, import: Kernel], [22, {:&, [], [1]}]},
                            {:+, [context: Elixir, import: Kernel], [{:&, [], [1]}, 1]}
                          ]},
                         6_700_417
                       ]}
                    ]}
                 ]}
              ]}
         ]
       ]}
    ]

    def |> Enum.map(&Optimizer.optimize_func(&1))
    @table_name |> :ets.match(:"$1")

    Pelemay.Generator.Native_CL.generate()
  end
end
